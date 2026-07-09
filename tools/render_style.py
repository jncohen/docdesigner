#!/usr/bin/env python3
"""Dev harness: flatten a style's tokens -> LaTeX preamble + pandoc call.

This is the executable specification for the R engine. It reads engine
defaults + a style's format.yml (resolving `inherits`), maps font families
to bundled files, writes a preamble, and renders a specimen PDF with pandoc.
"""
import sys, os, subprocess, yaml, copy

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(REPO, "inst", "fonts") + "/"
DEFAULTS = os.path.join(REPO, "inst", "engine", "defaults.yml")

FONT_REGISTRY = {
    "Source Serif 4": dict(regular="SourceSerif4-Regular.otf", bold="SourceSerif4-Bold.otf",
                            italic="SourceSerif4-It.otf", bolditalic="SourceSerif4-BoldIt.otf"),
    "EB Garamond":    dict(regular="EBGaramond-Regular.otf", bold="EBGaramond-Bold.otf",
                            italic="EBGaramond-Italic.otf", bolditalic="EBGaramond-BoldItalic.otf"),
    "XITS":           dict(regular="XITS-Regular.otf", bold="XITS-Bold.otf",
                            italic="XITS-Italic.otf", bolditalic="XITS-BoldItalic.otf"),
    "Fira Code":      dict(regular="FiraCode-Regular.ttf", bold="FiraCode-Bold.ttf"),
}

def deep_merge(base, over):
    out = copy.deepcopy(base)
    for k, v in (over or {}).items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = copy.deepcopy(v)
    return out

def load_style(path):
    with open(DEFAULTS) as f:
        spec = yaml.safe_load(f)
    with open(path) as f:
        style = yaml.safe_load(f)
    # resolve one level of inheritance from a sibling style dir
    parent = style.get("inherits")
    if parent:
        ppath = os.path.join(os.path.dirname(os.path.dirname(path)), parent, "format.yml")
        if os.path.exists(ppath):
            with open(ppath) as f:
                spec = deep_merge(spec, yaml.safe_load(f))
    return deep_merge(spec, style)

def font_family(cmd, family, path_needed=True):
    reg = FONT_REGISTRY[family]
    lines = [f"[Path={FONTS},"]
    lines.append(f"  BoldFont={reg['bold']},")
    if "italic" in reg:
        lines.append(f"  ItalicFont={reg['italic']},")
        lines.append(f"  BoldItalicFont={reg['bolditalic']},")
    body = "\n".join(lines).rstrip(",")
    return f"{cmd}{{{reg['regular']}}}[Path={FONTS}," + \
           (f"BoldFont={reg['bold']}," ) + \
           (f"ItalicFont={reg['italic']},BoldItalicFont={reg['bolditalic']}]" if "italic" in reg else "]")

def pt(size_str):
    return float(str(size_str).replace("pt", "").strip())

def preamble(s):
    ty, col, hd, ti = s["typography"], s["color"], s["headings"], s["title"]
    base = pt(ty["base_size"]); lh = ty["line_height"]
    out = []
    out.append("\\usepackage{fontspec}")
    out.append("\\usepackage{anyfontsize}")
    out.append(font_family("\\setmainfont", ty["body"]))
    mono = FONT_REGISTRY[ty["mono"]]
    out.append(f"\\setmonofont{{{mono['regular']}}}[Path={FONTS},BoldFont={mono['bold']},Scale=0.82]")
    if ty["heading"] != ty["body"]:
        out.append(font_family("\\newfontfamily\\ddheadfont", ty["heading"]))
        head_cmd = "\\ddheadfont"
    else:
        head_cmd = ""
    out.append("\\usepackage{xcolor}")
    for role in ("accent", "text", "muted", "rule"):
        out.append(f"\\definecolor{{{role}}}{{HTML}}{{{col[role].lstrip('#').upper()}}}")
    out.append(f"\\color{{text}}")
    out.append("\\usepackage[explicit]{titlesec}")
    def hspec(level, cmd):
        h = hd[level]; size = round(base*float(h["scale"]),1); lead = round(size*1.2,1)
        wt = "\\bfseries" if h.get("weight","bold")=="bold" else "\\mdseries"
        txt = "\\MakeUppercase{#1}" if h.get("case")=="upper" else "#1"
        label = "\\thesection\\hspace{0.6em}" if hd.get("number_sections") and cmd=="\\section" else ""
        fmt = f"{head_cmd}\\fontsize{{{size}}}{{{lead}}}\\selectfont{wt}\\color{{accent}}"
        line = f"\\titleformat{{{cmd}}}[block]{{{fmt}}}{{{label}}}{{0pt}}{{{txt}}}"
        if level=="h1" and h.get("rule"):
            line += "[\\vspace{2pt}{\\color{rule}\\titlerule[1pt]}]"
        return line
    out.append(hspec("h1","\\section"))
    out.append(hspec("h2","\\subsection"))
    out.append(hspec("h3","\\subsubsection"))
    out.append("\\titlespacing*{\\section}{0pt}{1.7em}{0.5em}")
    out.append("\\titlespacing*{\\subsection}{0pt}{1.1em}{0.3em}")
    out.append("\\titlespacing*{\\subsubsection}{0pt}{0.9em}{0.2em}")
    # title block
    out.append("\\usepackage{titling}")
    tsize = round(base*2.6,1)
    out.append(f"\\pretitle{{\\begin{{flushleft}}{head_cmd}\\fontsize{{{tsize}}}{{{round(tsize*1.1,1)}}}\\selectfont\\bfseries\\color{{accent}}}}")
    if ti["style"]=="rule":
        out.append("\\posttitle{\\par\\end{flushleft}\\vskip0.3em{\\color{rule}\\rule{\\linewidth}{2pt}}\\vskip0.4em}")
    elif ti["style"]=="bars":
        out.insert(len(out)-1, "% bars title")
        out.append("\\posttitle{\\par\\end{flushleft}\\vskip0.3em{\\color{accent}\\rule{\\linewidth}{3pt}}\\vskip0.4em}")
    else:
        out.append("\\posttitle{\\par\\end{flushleft}\\vskip0.4em}")
    out.append("\\preauthor{\\begin{flushleft}\\large\\color{muted}}")
    out.append("\\postauthor{\\end{flushleft}}")
    out.append("\\predate{\\begin{flushleft}\\color{muted}}")
    out.append("\\postdate{\\end{flushleft}}")
    out.append("\\usepackage{microtype}")
    out.append("\\usepackage{booktabs}")
    out.append("\\renewcommand{\\arraystretch}{1.2}")
    out.append("\\setlength{\\parindent}{0pt}")
    out.append(f"\\setlength{{\\parskip}}{{0.5em}}")
    out.append(f"\\linespread{{{lh}}}")
    out.append("\\usepackage{fancyhdr}\\pagestyle{fancy}\\fancyhf{}")
    out.append("\\renewcommand{\\headrulewidth}{0pt}\\renewcommand{\\footrulewidth}{0.4pt}")
    out.append("\\fancyfoot[R]{\\small\\color{muted}\\thepage}")
    return "\n".join(out)

def render(style_path, specimen, outpdf):
    s = load_style(style_path)
    header = outpdf.replace(".pdf","-header.tex")
    with open(header,"w") as f: f.write(preamble(s))
    base = pt(s["typography"]["base_size"])
    fontsize = "12pt" if base>=11.5 else ("11pt" if base>=10.5 else "10pt")
    args = ["pandoc", specimen, "-o", outpdf, "--pdf-engine=xelatex",
            "-H", header,
            "-V", f"geometry:margin={s['page']['margin']}",
            "-V", f"papersize={s['page']['papersize']}",
            "-V", f"fontsize={fontsize}",
            "-V", "colorlinks=true", "-V", "linkcolor=accent", "-V", "urlcolor=accent",
            "--highlight-style", s.get("highlight","tango")]
    if s["page"].get("columns",1)==2 and not os.environ.get("DD_ONECOL"):
        args += ["-V", "classoption=twocolumn"]
    if s["headings"].get("number_sections"):
        args += ["--number-sections"]
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode!=0:
        sys.stderr.write(r.stderr[-2000:]); sys.exit(1)
    print("OK:", outpdf)

if __name__=="__main__":
    render(sys.argv[1], sys.argv[2], sys.argv[3])
