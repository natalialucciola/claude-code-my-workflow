#!/usr/bin/env python3
"""Gera e mantém a página "Estado dos Capítulos" da tese.

Modos:
  python scripts/estado_capitulos/gerar.py                  # renderiza o livro e gera _site/
  python scripts/estado_capitulos/gerar.py --sem-render     # usa o _book/ existente
  python scripts/estado_capitulos/gerar.py --marcar-publicado
  python scripts/estado_capitulos/gerar.py --hook post      # hook PostToolUse (Bash)
  python scripts/estado_capitulos/gerar.py --hook sessao    # hook SessionStart
  python scripts/estado_capitulos/gerar.py --status         # mostra se a página está em dia

Só biblioteca padrão. Procedimento completo: scripts/estado_capitulos/README.md
"""
from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Caminhos cujo commit torna a página desatualizada.
WATCH = [
    "Quarto/thesis/chapters",
    "Quarto/thesis/_quarto.yml",
    "Quarto/thesis/Figures",
    "Bibliography_base.bib",
    "explorations",
    "scripts/R",
    "quality_reports/plans",
    "quality_reports/estado-capitulos/capitulos.json",
]
GIT_CMD_RE = re.compile(r"\bgit\b[^|;&]*\b(commit|merge|pull|cherry-pick|rebase|revert|am)\b")
STATUS_LABEL = {"ok": "sim", "part": "parcial", "no": "não", "na": "n/a"}
EXPLICIT_TYPES = {
    ".qmd": "text/plain",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
    ".ttf": "font/ttf",
    ".svg": "image/svg+xml",
}


def git(*args: str, cwd: Path | None = None) -> str:
    out = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, encoding="utf-8")
    return out.stdout.strip() if out.returncode == 0 else ""


ROOT = Path(git("rev-parse", "--show-toplevel") or ".").resolve()
DATA = ROOT / "quality_reports/estado-capitulos/capitulos.json"
SITE = ROOT / "quality_reports/estado-capitulos/_site"
TEMPLATE = Path(__file__).with_name("template.html")
BOOK = ROOT / "Quarto/thesis/_book"
CHAPTERS = ROOT / "Quarto/thesis/chapters"


def state_path() -> Path:
    """Estado no checkout principal (diretório comum do git), compartilhado entre worktrees."""
    common = Path(git("rev-parse", "--git-common-dir", cwd=ROOT) or ".git")
    if not common.is_absolute():
        common = ROOT / common
    return common.resolve().parent / ".claude/state/estado-capitulos.json"


def load_state() -> dict:
    try:
        return json.loads(state_path().read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def save_state(st: dict) -> None:
    p = state_path()
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(st, ensure_ascii=False, indent=2), encoding="utf-8")


def head_main() -> tuple[str, str]:
    """(hash, 'hash curto data assunto') do último commit do main nos caminhos vigiados."""
    line = git("log", "-1", "--format=%H\t%h %cs %s", "main", "--", *WATCH, cwd=ROOT)
    if not line:
        return "", ""
    h, desc = line.split("\t", 1)
    return h, desc


def current_branch() -> str:
    return git("rev-parse", "--abbrev-ref", "HEAD", cwd=ROOT)


# ---------------------------------------------------------------- hooks

def hook(mode: str) -> None:
    try:
        payload = json.load(sys.stdin) if mode == "post" else {}
    except ValueError:
        payload = {}
    if mode == "post":
        cmd = str((payload.get("tool_input") or {}).get("command", ""))
        if not GIT_CMD_RE.search(cmd):
            return
    if current_branch() != "main":
        return
    head, desc = head_main()
    st = load_state()
    if not head or head == st.get("publicado"):
        return
    if mode == "post" and head == st.get("avisado"):
        return
    st["avisado"] = head
    save_state(st)
    data = json.loads(DATA.read_text(encoding="utf-8")) if DATA.exists() else {}
    url = data.get("artifact_url", "(ver quality_reports/estado-capitulos/capitulos.json)")
    pub = st.get("publicado", "")[:7] or "nenhum registro neste computador"
    msg = (
        f"A página 'Estado dos Capítulos' ({url}) está desatualizada: o último commit do main nos "
        f"caminhos da tese é {desc}; a página foi publicada a partir de {pub}. Ao terminar o que "
        "está fazendo, atualize-a seguindo scripts/estado_capitulos/README.md: (1) se o commit mudou "
        "o estado de algum capítulo, atualize quality_reports/estado-capitulos/capitulos.json; "
        "(2) rode `python scripts/estado_capitulos/gerar.py`; (3) publique com a ferramenta Artifact "
        "usando quality_reports/estado-capitulos/_site/publicar.json; (4) rode "
        "`python scripts/estado_capitulos/gerar.py --marcar-publicado`. Avise a autora em uma linha."
    )
    event = "PostToolUse" if mode == "post" else "SessionStart"
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": msg}}, ensure_ascii=False))


# ---------------------------------------------------------------- página

def esc(s: str) -> str:
    return html.escape(s or "", quote=True)


def chapter_order() -> list[str]:
    txt = (ROOT / "Quarto/thesis/_quarto.yml").read_text(encoding="utf-8")
    return re.findall(r"chapters/([\w.-]+\.qmd)", txt)


def chapter_facts(fname: str) -> dict:
    path = CHAPTERS / fname
    txt = path.read_text(encoding="utf-8") if path.exists() else ""
    todos = len(re.findall(r"\bTODO\b", txt))
    prose = re.sub(r"<!--.*?-->", " ", txt, flags=re.S)
    prose = re.sub(r"```.*?```", " ", prose, flags=re.S)
    words = len(prose.split())
    sections = len(re.findall(r"^## ", txt, flags=re.M))
    last = git("log", "-1", "--format=%h|%cs", "--", f"Quarto/thesis/chapters/{fname}", cwd=ROOT)
    h, d = (last.split("|") + [""])[:2] if last else ("", "")
    return {"words": words, "sections": sections, "todos": todos, "hash": h, "date": d}


def gh_link(base: str, rel: str) -> str:
    if not base or "*" in rel:
        return ""
    kind = "tree" if (ROOT / rel).is_dir() else "blob"
    return f"{base}/{kind}/main/{rel}"


def chip(kind: str) -> str:
    kind = kind if kind in STATUS_LABEL else "no"
    return f'<span class="st {kind}">{STATUS_LABEL[kind]}</span>'


def words_tag(f: dict) -> str:
    if f["words"] < 25:
        return "só o título"
    n = f"{round(f['words'], -2):,}".replace(",", ".")
    parts = [f"≈ {n} palavras", f"{f['sections']} seções"]
    if f["todos"]:
        parts.append(f"{f['todos']} TODO" + ("s" if f["todos"] > 1 else ""))
    return " · ".join(parts)


def build_page(data: dict, order: list[str], has_book: bool, head_desc: str) -> str:
    base = data.get("github_base", "")
    caps = data.get("capitulos", {})
    rows, cards = [], []
    for i, fname in enumerate(order):
        c = caps.get(fname, {})
        f = chapter_facts(fname)
        prefix = fname.split("-", 1)[0]
        title = c.get("titulo") or fname
        st = c.get("status", {})
        read = f"livro/chapters/{fname[:-4]}.html"
        has_read = has_book and (BOOK / "chapters" / f"{fname[:-4]}.html").exists()
        anchor = f"cap-{prefix}"
        name = f'<a href="{read}">{esc(prefix)} {esc(title)}</a>' if has_read else f"{esc(prefix)} {esc(title)}"
        missing = "" if c else ' <span class="st part">sem descrição</span>'
        rows.append(
            f'          <tr><td class="cap">{name}{missing}<small>Cap. {i + 1} no livro · <a href="#{anchor}">detalhes</a></small></td>'
            + "".join(f"<td>{chip(st.get(k, 'no'))}</td>" for k in ("estrutura", "codigo", "prosa", "plano"))
            + f'<td class="next">{esc(c.get("acao_curta") or c.get("proxima_acao") or "Atualizar a descrição deste capítulo")}</td></tr>'
        )
        links = [
            f'<a class="btn primary" href="{read}">Ler (HTML)</a>' if has_read
            else '<span class="btn off">HTML indisponível</span>',
            f'<a class="btn" href="fonte/{esc(fname)}">Fonte (.qmd)</a>',
        ]
        gh = gh_link(base, f"Quarto/thesis/chapters/{fname}")
        if gh:
            links.append(f'<a class="btn" href="{gh}">GitHub</a>')
        facts = []
        if c.get("o_que_existe"):
            facts.append(f"<div><dt>O que existe</dt><dd>{esc(c['o_que_existe'])}</dd></div>")
        if c.get("pendencias"):
            facts.append(f"<div><dt>Pendências</dt><dd>{esc(c['pendencias'])}</dd></div>")
        paths = [f'<div><span class="k">Texto</span><span class="path">Quarto/thesis/chapters/{esc(fname)}</span></div>']
        for src in c.get("fontes", []):
            rel = src.get("caminho", "")
            url = gh_link(base, rel)
            item = f'<span class="path">{esc(rel)}</span>'
            if url:
                item += f' <a class="gh" href="{url}">GitHub</a>'
            paths.append(f'<div><span class="k">{esc(src.get("rotulo", ""))}</span>{item}</div>')
        changed = f" · alterado em {f['date']} ({f['hash']})" if f["hash"] else ""
        cards.append(
            f'      <article class="card" id="{anchor}">\n'
            f'        <div class="card-head"><h3>{esc(prefix)} · {esc(title)}</h3><span class="tag">{esc(words_tag(f))}{esc(changed)}</span></div>\n'
            + (f'        <p class="q">{esc(c["pergunta"])}</p>\n' if c.get("pergunta") else "")
            + '        <div class="chips">'
            + "".join(
                f'<span class="chip-group"><span class="lbl">{lbl}</span>{chip(st.get(k, "no"))}</span>'
                for k, lbl in (("estrutura", "Estrutura"), ("codigo", "Código"), ("prosa", "Prosa"), ("plano", "Plano"))
            )
            + "</div>\n"
            + f'        <div class="links">{"".join(links)}</div>\n'
            + (f'        <dl class="facts">{"".join(facts)}</dl>\n' if facts else "")
            + f'        <div class="action"><b>Próxima ação</b><p>{esc(c.get("proxima_acao") or "Atualizar a descrição deste capítulo em capitulos.json.")}</p></div>\n'
            + f'        <div class="paths">{"".join(paths)}</div>\n'
            + "      </article>"
        )
    cross = [
        f'      <article><h3>{esc(t.get("titulo", ""))}</h3><p>{esc(t.get("texto", ""))}</p></article>'
        for t in data.get("transversais", [])
    ]
    now = dt.datetime.now().strftime("%d/%m/%Y %H:%M")
    rodape = f"Gerada em {now} a partir do commit {head_desc or '(sem commit)'} do main."
    page = TEMPLATE.read_text(encoding="utf-8")
    for key, val in {
        "{{TITULO}}": esc(data.get("titulo", "Estado dos capítulos")),
        "{{SUBTITULO}}": esc(data.get("subtitulo", "")),
        "{{LIVRO_INDEX}}": "livro/index.html" if has_book else "#h-resumo",
        "{{TABELA}}": "\n".join(rows),
        "{{FICHAS}}": "\n".join(cards),
        "{{TRANSVERSAIS}}": "\n".join(cross),
        "{{RODAPE}}": esc(rodape),
    }.items():
        page = page.replace(key, val)
    return page


def build(render: bool) -> None:
    if render:
        if shutil.which("quarto"):
            r = subprocess.run(["quarto", "render", "Quarto/thesis"], cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
            if r.returncode != 0:
                print("AVISO: quarto render falhou; usando o _book/ existente.\n" + r.stderr[-1500:], file=sys.stderr)
        else:
            print("AVISO: quarto não encontrado; usando o _book/ existente (se houver).", file=sys.stderr)
    data = json.loads(DATA.read_text(encoding="utf-8"))
    order = chapter_order()
    has_book = (BOOK / "index.html").exists()
    head, desc = head_main()

    if SITE.exists():
        shutil.rmtree(SITE)
    (SITE / "fonte").mkdir(parents=True)
    if has_book:
        shutil.copytree(BOOK, SITE / "livro")
    for fname in order:
        src = CHAPTERS / fname
        if src.exists():
            shutil.copy2(src, SITE / "fonte" / fname)
    (SITE / "index.html").write_text(build_page(data, order, has_book, desc), encoding="utf-8")

    files: dict[str, object] = {}
    for p in sorted(SITE.rglob("*")):
        if not p.is_file() or p.name in ("index.html", "publicar.json") and p.parent == SITE:
            continue
        pub = p.relative_to(SITE).as_posix()
        src = p.relative_to(ROOT).as_posix()
        ctype = EXPLICIT_TYPES.get(p.suffix.lower())
        files[pub] = {"from": src, "contentType": ctype} if ctype else src
    removed = [p for p in load_state().get("arquivos_publicados", []) if p not in files]
    for p in removed:
        files[p] = None
    manifest = {
        "url": data.get("artifact_url"),
        "file_path": (SITE / "index.html").relative_to(ROOT).as_posix(),
        "files": files,
        "commit_main": head,
        "commit_desc": desc,
        "arquivos": len([v for v in files.values() if v is not None]),
        "removidos": removed,
    }
    (SITE / "publicar.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    sem_desc = [f for f in order if f not in data.get("capitulos", {})]
    print(f"Página gerada: {manifest['file_path']}")
    print(f"Arquivos de apoio: {manifest['arquivos']} (removidos: {len(removed)}); livro incluído: {'sim' if has_book else 'não'}")
    print(f"Commit do main: {desc or '(nenhum)'}")
    if sem_desc:
        print("AVISO: capítulos sem descrição em capitulos.json: " + ", ".join(sem_desc))
    if current_branch() != "main":
        print(f"AVISO: este checkout está no branch '{current_branch()}', não no main; a página reflete este branch.")


def marcar() -> None:
    manifest = json.loads((SITE / "publicar.json").read_text(encoding="utf-8"))
    st = load_state()
    st["publicado"] = manifest.get("commit_main", "")
    st["avisado"] = st["publicado"]
    st["arquivos_publicados"] = sorted(k for k, v in manifest["files"].items() if v is not None)
    st["publicado_em"] = dt.datetime.now().isoformat(timespec="seconds")
    save_state(st)
    print(f"Marcado como publicado: {manifest.get('commit_desc', '')}")


def status() -> None:
    head, desc = head_main()
    st = load_state()
    ok = head and head == st.get("publicado")
    print(f"main: {desc}\npublicado: {st.get('publicado', '')[:7] or '(nenhum)'} em {st.get('publicado_em', '-')}")
    print("Página em dia." if ok else "Página desatualizada.")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sem-render", action="store_true")
    ap.add_argument("--marcar-publicado", action="store_true")
    ap.add_argument("--hook", choices=["post", "sessao"])
    ap.add_argument("--status", action="store_true")
    a = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if a.hook:
        try:
            hook(a.hook)
        except Exception:  # um hook nunca deve atrapalhar a sessão
            pass
        return
    if a.status:
        status()
    elif a.marcar_publicado:
        marcar()
    else:
        build(render=not a.sem_render)


if __name__ == "__main__":
    main()
