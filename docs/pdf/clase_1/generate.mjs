import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../../..');
const require = createRequire(import.meta.url);
const MarkdownIt = require('../shared/vendor/markdown-it.cjs');
const outputDir = here;
const outputFile = path.join(outputDir, 'Linux-desde-cero-Clase-1.html');

fs.mkdirSync(outputDir, { recursive: true });

const md = new MarkdownIt({
  html: false,
  linkify: true,
  typographer: true,
});

const languageLabels = {
  bash: 'TERMINAL · BASH',
  sh: 'TERMINAL · SHELL',
  shell: 'TERMINAL · SHELL',
  text: 'SALIDA REPRESENTATIVA',
};

md.renderer.rules.fence = (tokens, index) => {
  const token = tokens[index];
  const language = (token.info || 'text').trim().split(/\s+/)[0].toLowerCase();
  const label = languageLabels[language] || language.toUpperCase();
  const outputClass = language === 'text' ? ' codebox--output' : '';
  return `<figure class="codebox${outputClass}"><figcaption><span class="terminal-dots"><i></i><i></i><i></i></span><span>${label}</span></figcaption><pre><code>${md.utils.escapeHtml(token.content)}</code></pre></figure>`;
};

const defaultLinkOpen = md.renderer.rules.link_open || ((tokens, idx, options, env, self) => self.renderToken(tokens, idx, options));
md.renderer.rules.link_open = (tokens, idx, options, env, self) => {
  const hrefIndex = tokens[idx].attrIndex('href');
  const href = hrefIndex >= 0 ? tokens[idx].attrs[hrefIndex][1] : '';
  if (/^https?:\/\//.test(href)) {
    tokens[idx].attrSet('target', '_blank');
    return defaultLinkOpen(tokens, idx, options, env, self);
  }
  tokens[idx].tag = 'span';
  tokens[idx].attrs = [['class', 'local-reference']];
  return self.renderToken(tokens, idx, options);
};
md.renderer.rules.link_close = (tokens, idx, options, env, self) => {
  const lastOpen = [...tokens.slice(0, idx)].reverse().find((token) => token.type === 'link_open');
  if (lastOpen && lastOpen.tag === 'span') {
    tokens[idx].tag = 'span';
  }
  return self.renderToken(tokens, idx, options);
};

function source(file, stopAt) {
  let text = fs.readFileSync(path.join(repo, file), 'utf8');
  if (stopAt) {
    const stop = text.indexOf(stopAt);
    if (stop >= 0) text = text.slice(0, stop).trimEnd();
  }
  text = text.replace(/^# .+\n+/, '');
  return text;
}

const tocEntries = [];
const slugCounts = new Map();

function slugify(value) {
  const base = value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '') || 'apartado';
  const count = (slugCounts.get(base) || 0) + 1;
  slugCounts.set(base, count);
  return count === 1 ? base : `${base}-${count}`;
}

function renderChapter(file, stopAt, chapterKey) {
  const env = {};
  const tokens = md.parse(source(file, stopAt), env);

  for (let index = 0; index < tokens.length - 1; index += 1) {
    const token = tokens[index];
    if (token.type !== 'heading_open' || !['h2', 'h3'].includes(token.tag)) continue;

    const inline = tokens[index + 1];
    const title = inline.children
      .filter((child) => ['text', 'code_inline'].includes(child.type))
      .map((child) => child.content)
      .join('')
      .trim();
    const id = `${chapterKey}-${slugify(title)}`;
    token.attrSet('id', id);
    tocEntries.push({ chapterKey, level: Number(token.tag.slice(1)), title, id });

    const backLink = new inline.constructor('html_inline', '', 0);
    backLink.content = '<a class="toc-back" href="#indice-interactivo" aria-label="Volver al índice">Índice ↑</a>';
    inline.children.push(backLink);
  }

  return md.renderer.render(tokens, md.options, env)
    .replaceAll('<p>Salida representativa:</p>', '<p class="micro-label">Salida representativa</p>')
    .replaceAll('<p>Sintaxis general:</p>', '<p class="micro-label">Sintaxis general</p>')
    .replaceAll('<p>Ejemplos resueltos:</p>', '<p class="micro-label">Ejemplos resueltos</p>')
    .replaceAll('<p>Ejemplo resuelto para copiar:</p>', '<p class="micro-label">Ejemplo resuelto para copiar</p>');
}

const chapter1 = renderChapter('01-introduccion-a-linux.md', undefined, 'c1');
const chapter3 = renderChapter('03-estructura-del-sistema-de-archivos-de-linux.md', undefined, 'c3');
const chapter7 = renderChapter('07-el-shell.md', '\n## 7.16 Espacio:', 'c7');

const tocChapters = [
  { key: 'c1', id: 'capitulo-1', label: 'Capítulo 1', title: 'Introducción a Linux' },
  { key: 'c3', id: 'capitulo-3', label: 'Capítulo 3', title: 'Estructura del sistema de archivos' },
  { key: 'c7', id: 'capitulo-7', label: 'Capítulo 7.1–7.15', title: 'El shell' },
];

function tocGroup(chapter) {
  const links = tocEntries
    .filter((entry) => entry.chapterKey === chapter.key)
    .map((entry) => `<a class="toc-link toc-level-${entry.level}" href="#${entry.id}"><span>${md.utils.escapeHtml(entry.title)}</span><b>→</b></a>`)
    .join('');
  return `<section class="toc-group"><a class="toc-chapter" href="#${chapter.id}"><small>${chapter.label}</small><strong>${chapter.title}</strong></a>${links}</section>`;
}

const tocChapter1 = tocGroup(tocChapters[0]);
const tocChapter3 = tocGroup(tocChapters[1]);
const tocChapter7 = tocGroup(tocChapters[2]);

const agenda = [
  ['09:00–09:20', 'Verificar el entorno con <code>whoami</code>, <code>hostname</code>, <code>pwd</code> y <code>/etc/os-release</code>.'],
  ['09:20–10:00', 'Kernel, distribución, shell, terminal y escritorio.'],
  ['10:00–10:40', 'Usuarios, grupos y <code>sudo</code>; práctica controlada.'],
  ['10:40–11:00', 'Flujo mínimo de <code>apt</code>.'],
  ['11:00–11:30', '<strong>Receso.</strong>', 'break-row'],
  ['11:30–12:15', 'Jerarquía, rutas y tipos de archivo.'],
  ['12:15–13:05', '<code>pwd</code>, <code>ls</code>, <code>cd</code>, <code>mkdir</code>, <code>touch</code>, <code>cp</code>, <code>mv</code>, <code>rm</code> y <code>file</code>.'],
  ['13:05–13:40', 'Enlaces, permisos, propietario y grupo.'],
  ['13:40–13:55', 'Reto 3: directorio compartido.'],
  ['13:55–14:00', 'Evidencia y cierre.'],
];

const agendaRows = agenda.map(([time, activity, rowClass = '']) => `
  <tr class="${rowClass}">
    <td class="agenda-time">${time}</td>
    <td class="agenda-activity">${activity}</td>
  </tr>`).join('');

const html = `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Linux desde cero · Clase 1</title>
  <style>
    @font-face {
      font-family: 'Poppins';
      src: url('../shared/fonts/Poppins-400.woff2') format('woff2');
      font-weight: 400;
      font-style: normal;
    }
    @font-face {
      font-family: 'Poppins';
      src: url('../shared/fonts/Poppins-500.woff2') format('woff2');
      font-weight: 500;
      font-style: normal;
    }
    @font-face {
      font-family: 'Poppins';
      src: url('../shared/fonts/Poppins-600.woff2') format('woff2');
      font-weight: 600;
      font-style: normal;
    }
    @font-face {
      font-family: 'Poppins';
      src: url('../shared/fonts/Poppins-700.woff2') format('woff2');
      font-weight: 700;
      font-style: normal;
    }
    @font-face {
      font-family: 'Montserrat';
      src: url('../shared/fonts/Montserrat-400.woff2') format('woff2');
      font-weight: 400;
      font-style: normal;
    }
    @font-face {
      font-family: 'Montserrat';
      src: url('../shared/fonts/Montserrat-600.woff2') format('woff2');
      font-weight: 600;
      font-style: normal;
    }
    @font-face {
      font-family: 'Montserrat';
      src: url('../shared/fonts/Montserrat-700.woff2') format('woff2');
      font-weight: 700;
      font-style: normal;
    }

    :root {
      --blue: #0a78aa;
      --blue-deep: #243d5a;
      --blue-dark: #10263d;
      --blue-soft: #eaf3f7;
      --blue-pale: #f4f8fa;
      --red: #ff1f4b;
      --ink: #243447;
      --muted: #607084;
      --line: #d9e3e8;
      --paper: #ffffff;
    }

    * { box-sizing: border-box; }
    .svg-defs {
      position: absolute;
      width: 0;
      height: 0;
      overflow: hidden;
      pointer-events: none;
    }

    @page {
      size: Letter portrait;
      margin: 0.76in 0.70in 0.67in 0.70in;
      @top-left {
        content: 'CLASE 1';
        padding-top: 0.12in;
        border-bottom: 1px solid #b8cad4;
        color: #ff1f4b;
        font-family: 'Poppins', Arial, sans-serif;
        font-size: 7pt;
        font-weight: 700;
        letter-spacing: .16em;
      }
      @top-right {
        content: 'TECGURUS · LINUX DESDE CERO';
        padding-top: 0.12in;
        border-bottom: 1px solid #b8cad4;
        color: #708291;
        font-family: 'Poppins', Arial, sans-serif;
        font-size: 6.8pt;
        font-weight: 600;
        letter-spacing: .05em;
      }
      @top-right-corner {
        content: '';
        background: linear-gradient(135deg, transparent 0 43%, #0a78aa 44% 100%);
      }
      @bottom-left {
        content: 'LINUX DESDE CERO';
        padding-left: 0.48in;
        padding-bottom: 0.09in;
        border-top: 1px solid #b8cad4;
        color: #243d5a;
        background:
          linear-gradient(90deg, #ff1f4b 0 0.18in, transparent 0.18in 0.23in, #0a78aa 0.23in 0.42in, transparent 0.42in) left 0.11in / 0.44in 0.06in no-repeat;
        font-family: 'Poppins', Arial, sans-serif;
        font-size: 6.8pt;
        font-weight: 600;
        letter-spacing: .04em;
      }
      @bottom-right {
        content: 'CLASE 1  ·  ' counter(page);
        padding-bottom: 0.09in;
        border-top: 1px solid #b8cad4;
        color: #708291;
        font-family: 'Poppins', Arial, sans-serif;
        font-size: 6.8pt;
        font-weight: 600;
        letter-spacing: .05em;
      }
      @bottom-right-corner {
        content: '';
        background: linear-gradient(315deg, #0a78aa 0 36%, transparent 37% 100%);
      }
    }
    @page cover {
      size: Letter portrait;
      margin: 0;
    }
    @page divider {
      size: Letter portrait;
      margin: 0;
    }
    @page overview {
      size: Letter portrait;
      margin: 0;
    }

    html, body {
      margin: 0;
      padding: 0;
      color: var(--ink);
      background: white;
      font-family: 'Montserrat', Arial, sans-serif;
      font-size: 9.8pt;
      line-height: 1.48;
      print-color-adjust: exact;
      -webkit-print-color-adjust: exact;
    }

    /* El marco corporativo se repite en cada página de contenido. */
    .page-furniture {
      position: fixed;
      z-index: 0;
      inset: 0;
      pointer-events: none;
      display: none;
    }
    .frame-border {
      position: fixed;
      top: -0.61in;
      right: -0.55in;
      bottom: -0.52in;
      left: -0.55in;
      border: 1.1px solid #b8cad4;
      border-radius: 7px;
    }
    .frame-top-blue {
      position: fixed;
      top: -0.76in;
      right: -0.70in;
      width: 2.35in;
      height: 0.52in;
      background: var(--blue);
      clip-path: polygon(17% 0, 100% 0, 100% 100%, 0 100%);
    }
    .frame-top-red {
      position: fixed;
      top: -0.30in;
      right: -0.70in;
      width: 1.18in;
      height: 0.08in;
      background: var(--red);
    }
    .frame-bottom-blue {
      position: fixed;
      bottom: -0.67in;
      left: -0.70in;
      width: 1.62in;
      height: 0.28in;
      background: var(--blue);
      clip-path: polygon(0 0, 76% 0, 100% 100%, 0 100%);
    }
    .frame-bottom-red {
      position: fixed;
      bottom: -0.67in;
      left: -0.70in;
      width: 0.58in;
      height: 0.34in;
      background: var(--red);
      clip-path: polygon(0 0, 68% 0, 100% 100%, 0 100%);
    }
    .frame-brand {
      position: fixed;
      top: -0.54in;
      left: 0;
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--blue-deep);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 8pt;
      font-weight: 600;
      letter-spacing: 0.03em;
      text-transform: uppercase;
    }
    .frame-brand::before {
      content: '';
      width: 0.20in;
      height: 0.07in;
      border-radius: 99px;
      background: var(--red);
      box-shadow: 0.24in 0 0 var(--blue);
      margin-right: 0.22in;
    }
    .frame-footer {
      position: fixed;
      right: 0;
      bottom: -0.48in;
      color: #708291;
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 7.2pt;
      font-weight: 500;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }

    .cover {
      page: cover;
      position: relative;
      z-index: 5;
      width: 8.5in;
      height: 11in;
      overflow: hidden;
      background: #fff;
      break-after: page;
      font-family: 'Poppins', Arial, sans-serif;
    }
    .cover::before {
      content: '';
      position: absolute;
      inset: 0;
      background:
        radial-gradient(circle at 0.5px 0.5px, rgba(10,120,170,.14) .7px, transparent .8px) 7.73in 7.83in / 9px 9px no-repeat,
        linear-gradient(145deg, transparent 0 61%, rgba(234,243,247,.75) 61% 68%, transparent 68%);
      pointer-events: none;
    }
    .cover-top-shadow {
      position: absolute;
      top: 0.42in;
      left: 2.45in;
      width: 1.82in;
      height: 1.50in;
      background: #eff5f8;
      clip-path: url(#rounded-hexagon);
    }
    .cover-top-panel {
      position: absolute;
      top: 0.12in;
      left: 0;
      width: 3.33in;
      height: 2.15in;
      background: linear-gradient(135deg, #3176aa, #256a9d);
      clip-path: url(#rounded-chevron);
    }
    .cover-top-panel .dots {
      position: absolute;
      top: 1.43in;
      left: 0;
      width: 0.20in;
      height: 0.36in;
      background-image: radial-gradient(circle, #fff 1.1px, transparent 1.2px);
      background-size: 8px 8px;
      opacity: .95;
    }
    .cover-logo {
      position: absolute;
      top: 1.63in;
      left: 0.34in;
      width: 2.20in;
      height: auto;
    }
    .cover-title {
      position: absolute;
      top: 3.22in;
      left: 0.96in;
      width: 6.45in;
    }
    .cover-kicker {
      margin-bottom: 0.12in;
      color: var(--blue);
      font-size: 11.5pt;
      font-weight: 600;
      letter-spacing: .18em;
      text-transform: uppercase;
    }
    .cover h1 {
      margin: 0;
      color: var(--blue-deep);
      font-size: 47pt;
      line-height: 1.05;
      letter-spacing: -0.035em;
      font-weight: 700;
    }
    .cover-subtitle {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      margin-top: 0.31in;
      color: var(--blue-deep);
      font-size: 16.5pt;
      font-weight: 500;
    }
    .cover-subtitle .class-pill {
      display: inline-block;
      padding: 6px 13px 5px;
      border-radius: 4px;
      color: white;
      background: var(--red);
      font-size: 10pt;
      font-weight: 700;
      letter-spacing: .10em;
      text-transform: uppercase;
    }
    .cover-url {
      position: absolute;
      top: 6.28in;
      left: 0.97in;
      color: var(--red);
      font-size: 14.5pt;
      font-weight: 500;
    }
    .cover-instructor {
      position: absolute;
      left: 0.97in;
      bottom: 2.48in;
      padding-left: 0.18in;
      border-left: 4px solid var(--blue);
      color: var(--blue-deep);
      font-size: 11pt;
      line-height: 1.45;
    }
    .cover-instructor span {
      display: block;
      color: var(--muted);
      font-size: 8.2pt;
      font-weight: 600;
      letter-spacing: .12em;
      text-transform: uppercase;
    }
    .cover-bottom-panel {
      position: absolute;
      left: 0;
      bottom: 0;
      width: 3.18in;
      height: 1.58in;
      background: linear-gradient(135deg, #3176aa, #276d9f);
      clip-path: url(#rounded-bottom-panel);
    }
    .photo-blue-back {
      position: absolute;
      right: 0.68in;
      bottom: 0.36in;
      width: 3.86in;
      height: 2.88in;
      background: #3176aa;
      clip-path: url(#rounded-hexagon);
    }
    .photo-red-back {
      position: absolute;
      right: 0.12in;
      bottom: 1.34in;
      width: 4.12in;
      height: 3.24in;
      background: var(--red);
      clip-path: url(#rounded-hexagon);
    }
    .cover-photo {
      position: absolute;
      right: 0.05in;
      bottom: 1.47in;
      width: 3.87in;
      height: 2.96in;
      object-fit: cover;
      object-position: 57% 50%;
      clip-path: url(#rounded-hexagon);
      outline: 3px solid white;
    }
    .cover-hex-outline {
      position: absolute;
      right: 1.43in;
      bottom: 1.46in;
      width: 1.08in;
      height: 0.94in;
      border: 2px solid rgba(255,255,255,.94);
      border-radius: 9px;
      transform: rotate(60deg);
    }
    .cover-hex-outline::before,
    .cover-hex-outline::after {
      content: '';
      position: absolute;
      inset: -2px;
      border: inherit;
      border-radius: inherit;
      transform: rotate(60deg);
    }
    .cover-hex-outline::after { transform: rotate(120deg); }

    .overview {
      page: overview;
      position: relative;
      z-index: 5;
      width: 8.5in;
      height: 11in;
      padding: 0.74in 0.72in 0.55in;
      overflow: hidden;
      background: white;
      break-after: page;
    }
    .overview::before {
      content: '';
      position: absolute;
      top: 0;
      right: 0;
      width: 2.1in;
      height: 1.25in;
      background: var(--blue);
      clip-path: url(#rounded-slant-right-wide);
    }
    .overview::after {
      content: '';
      position: absolute;
      left: 0;
      bottom: 0;
      width: 1.4in;
      height: 0.40in;
      background: var(--red);
      clip-path: url(#rounded-bottom-panel);
    }
    .overview-header {
      position: relative;
      z-index: 2;
      margin-bottom: 0.15in;
    }
    .overview-kicker {
      color: var(--red);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 8.5pt;
      font-weight: 700;
      letter-spacing: .15em;
      text-transform: uppercase;
    }
    .overview h2 {
      margin: 0.05in 0 0;
      max-width: 5.45in;
      color: var(--blue-deep);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 21pt;
      line-height: 1.12;
      letter-spacing: -.025em;
    }
    .overview-files {
      position: relative;
      z-index: 2;
      margin: 0 0 0.16in;
      padding: 0.11in 0.14in;
      border-left: 4px solid var(--blue);
      color: var(--ink);
      background: var(--blue-pale);
      font-size: 9.2pt;
    }
    .overview-files strong {
      color: var(--blue-deep);
      font-family: 'Poppins', Arial, sans-serif;
      font-weight: 700;
    }
    .overview-files .chapter-number {
      color: var(--blue);
      font-weight: 700;
    }
    .agenda-table {
      position: relative;
      z-index: 2;
      width: 100%;
      border-collapse: separate;
      border-spacing: 0;
      font-size: 8.3pt;
      line-height: 1.25;
      overflow: hidden;
      border: 1px solid var(--line);
      border-radius: 8px;
    }
    .agenda-table th {
      padding: 0.09in 0.11in;
      color: var(--blue-deep);
      background: #edf4f7;
      border-bottom: 2px solid var(--blue);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 7.6pt;
      font-weight: 700;
      letter-spacing: .06em;
      text-align: left;
      text-transform: uppercase;
    }
    .agenda-table th:first-child { width: 1.10in; }
    .agenda-table td {
      padding: 0.087in 0.11in;
      border-bottom: 1px solid var(--line);
      vertical-align: middle;
    }
    .agenda-table tr:last-child td { border-bottom: 0; }
    .agenda-table tr:nth-child(even) td { background: #f7fafb; }
    .agenda-table .agenda-time {
      width: 1.10in;
      color: var(--blue);
      font-weight: 700;
      white-space: nowrap;
    }
    .agenda-table .agenda-activity {
      color: var(--blue-deep);
    }
    .agenda-table code {
      padding: 1px 4px 2px;
      border: 1px solid #d6e4ea;
      border-radius: 4px;
      color: #174f6d;
      background: #eef5f8;
      font-family: 'Noto Sans Mono', 'DejaVu Sans Mono', monospace;
      font-size: .91em;
      font-variant-ligatures: none;
    }
    .agenda-table .break-row td { background: #fff2f5 !important; }
    .overview-foot {
      margin-top: 0.18in;
    }
    .overview-note {
      padding: 0.12in 0.14in;
      border-left: 4px solid var(--red);
      background: var(--blue-pale);
      font-size: 7.8pt;
      line-height: 1.35;
    }
    .overview-note p { margin: 0 0 0.035in; }
    .overview-note p:last-child { margin-bottom: 0; }
    .overview-note strong {
      color: var(--blue-deep);
      font-family: 'Poppins', Arial, sans-serif;
      font-weight: 700;
    }

    .toc-page {
      page: overview;
      position: relative;
      z-index: 5;
      width: 8.5in;
      height: 11in;
      padding: 0.72in 0.74in 0.55in;
      overflow: hidden;
      background: white;
      break-after: page;
    }
    .toc-page::before {
      content: '';
      position: absolute;
      top: 0;
      right: 0;
      width: 2.1in;
      height: 1.25in;
      background: var(--blue);
      clip-path: url(#rounded-slant-right-wide);
    }
    .toc-page::after {
      content: '';
      position: absolute;
      left: 0;
      bottom: 0;
      width: 1.4in;
      height: 0.40in;
      background: var(--red);
      clip-path: url(#rounded-bottom-panel);
    }
    .toc-header {
      position: relative;
      z-index: 2;
      margin-bottom: 0.24in;
    }
    .toc-kicker {
      color: var(--red);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 8pt;
      font-weight: 700;
      letter-spacing: .16em;
      text-transform: uppercase;
    }
    .toc-page h2 {
      margin: 0.05in 0 0.05in;
      color: var(--blue-deep);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 27pt;
      line-height: 1.08;
      letter-spacing: -.025em;
    }
    .toc-description {
      max-width: 5.6in;
      margin: 0;
      color: var(--muted);
      font-size: 8.2pt;
    }
    .toc-grid {
      position: relative;
      z-index: 2;
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.26in;
      align-items: start;
    }
    .toc-single .toc-grid {
      grid-template-columns: 1fr;
      max-width: 6.82in;
    }
    .toc-group {
      overflow: hidden;
      border: 1px solid #d2e0e7;
      border-radius: 8px;
      background: white;
    }
    .toc-chapter {
      display: block;
      padding: 0.12in 0.14in;
      color: white;
      background: var(--blue);
      text-decoration: none;
    }
    .toc-chapter small {
      display: block;
      margin-bottom: 1px;
      color: rgba(255,255,255,.78);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 6.6pt;
      font-weight: 600;
      letter-spacing: .10em;
      text-transform: uppercase;
    }
    .toc-chapter strong {
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 10pt;
      font-weight: 600;
    }
    .toc-link {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      gap: 0.10in;
      min-height: 0.29in;
      padding: 0.06in 0.11in;
      border-bottom: 1px solid #e1e9ed;
      color: var(--blue-deep);
      background: white;
      font-size: 7.3pt;
      line-height: 1.26;
      text-decoration: none;
    }
    .toc-link:last-child { border-bottom: 0; }
    .toc-link:nth-child(odd) { background: #f8fafb; }
    .toc-link b {
      flex: 0 0 auto;
      color: var(--red);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 7.5pt;
    }
    .toc-level-2 { font-weight: 600; }
    .toc-level-3 {
      padding-left: 0.26in;
      color: #5f7182;
      font-size: 6.9pt;
    }
    .toc-level-3 span::before {
      content: '•';
      margin-right: 0.06in;
      color: var(--red);
    }
    .toc-nav {
      position: relative;
      z-index: 2;
      display: flex;
      justify-content: flex-end;
      margin-top: 0.16in;
    }
    .toc-nav a {
      padding: 0.06in 0.11in;
      border: 1px solid #c8d9e1;
      border-radius: 99px;
      color: var(--blue);
      background: white;
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 6.8pt;
      font-weight: 600;
      text-decoration: none;
    }

    .section-divider {
      page: divider;
      position: relative;
      z-index: 5;
      width: 8.5in;
      height: 11in;
      overflow: hidden;
      background: white;
      break-before: page;
      break-after: page;
      font-family: 'Poppins', Arial, sans-serif;
    }
    .section-divider .divider-panel {
      position: absolute;
      top: 0;
      right: 0;
      width: 3.12in;
      height: 4.38in;
      background: var(--blue);
      clip-path: url(#rounded-slant-right);
    }
    .section-divider .divider-panel::after {
      content: '';
      position: absolute;
      right: 0;
      bottom: 0.22in;
      width: 1.08in;
      height: 0.13in;
      background: var(--red);
    }
    .section-divider .divider-red {
      position: absolute;
      left: 0;
      bottom: 0;
      width: 1.35in;
      height: 3.10in;
      background: var(--red);
      clip-path: url(#rounded-slant-left);
    }
    .section-divider .divider-blue-foot {
      position: absolute;
      left: 0;
      bottom: 0;
      width: 2.2in;
      height: 0.48in;
      background: var(--blue);
    }
    .section-divider .divider-dots {
      position: absolute;
      right: 0.10in;
      top: 0.10in;
      width: 0.38in;
      height: 0.34in;
      background-image: radial-gradient(circle, #fff 1px, transparent 1.1px);
      background-size: 8px 8px;
    }
    .divider-content {
      position: absolute;
      top: 2.45in;
      left: 1.02in;
      width: 6.35in;
    }
    .divider-number {
      display: grid;
      width: 0.82in;
      height: 0.82in;
      place-items: center;
      margin-bottom: 0.42in;
      border: 3px solid var(--blue);
      border-radius: 50%;
      color: var(--blue);
      font-size: 19pt;
      font-weight: 700;
    }
    .divider-kicker {
      color: var(--red);
      font-size: 9pt;
      font-weight: 700;
      letter-spacing: .18em;
      text-transform: uppercase;
    }
    .section-divider h2 {
      max-width: 4.95in;
      margin: 0.13in 0 0.18in;
      color: var(--blue-deep);
      font-size: 31.5pt;
      line-height: 1.08;
      letter-spacing: -.035em;
    }
    .divider-description {
      max-width: 5.50in;
      color: var(--muted);
      font-family: 'Montserrat', Arial, sans-serif;
      font-size: 12pt;
      line-height: 1.48;
    }
    .divider-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 0.30in;
    }
    .divider-tags span {
      padding: 6px 10px 5px;
      border: 1px solid #c9d8e0;
      border-radius: 99px;
      color: var(--blue-deep);
      background: white;
      font-size: 7.4pt;
      font-weight: 600;
    }

    article.chapter {
      position: relative;
      z-index: 1;
      page: auto;
    }
    article.chapter h2 {
      position: relative;
      break-before: page;
      break-after: avoid;
      margin: 0 0 0.24in;
      padding: 0 0.72in 0.13in 0;
      color: var(--blue-deep);
      border-bottom: 2px solid var(--blue);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 21pt;
      line-height: 1.14;
      letter-spacing: -.018em;
    }
    article.chapter h3 {
      position: relative;
      break-after: avoid;
      margin: 0.25in 0 0.12in;
      padding-right: 0.66in;
      color: var(--blue);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 13pt;
      line-height: 1.23;
    }
    .toc-back {
      position: absolute;
      right: 0;
      top: 0.03in;
      padding: 2px 6px;
      border: 1px solid #cadbe3;
      border-radius: 99px;
      color: var(--blue) !important;
      background: white;
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 6.2pt;
      font-weight: 600;
      letter-spacing: .02em;
      text-decoration: none !important;
      white-space: nowrap;
    }
    article.chapter h2 .toc-back { top: 0.04in; }
    article.chapter h4 {
      break-after: avoid;
      margin: 0.20in 0 0.08in;
      color: var(--blue-deep);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 10.3pt;
    }
    article.chapter p {
      margin: 0 0 0.12in;
      orphans: 3;
      widows: 3;
    }
    article.chapter strong { color: var(--blue-deep); }
    article.chapter em { color: #44586c; }
    article.chapter a {
      color: var(--blue);
      text-decoration-color: rgba(10,120,170,.45);
      text-underline-offset: 2px;
    }
    .local-reference {
      display: inline-block;
      padding: 2px 7px;
      border-radius: 4px;
      color: var(--blue);
      background: var(--blue-soft);
      font-size: 8.2pt;
      font-weight: 600;
    }
    article.chapter ul,
    article.chapter ol {
      margin: 0.05in 0 0.15in 0.22in;
      padding-left: 0.18in;
    }
    article.chapter li {
      margin: 0.035in 0;
      padding-left: 0.035in;
      orphans: 2;
      widows: 2;
    }
    article.chapter li::marker { color: var(--red); font-weight: 700; }
    article.chapter input[type='checkbox'] {
      width: 0.13in;
      height: 0.13in;
      margin-right: 0.06in;
      accent-color: var(--blue);
    }
    article.chapter code {
      padding: 1px 4px 2px;
      border: 1px solid #d6e4ea;
      border-radius: 4px;
      color: #174f6d;
      background: #eef5f8;
      font-family: 'Noto Sans Mono', 'DejaVu Sans Mono', monospace;
      font-size: .91em;
      font-variant-ligatures: none;
      text-rendering: geometricPrecision;
    }
    .micro-label {
      margin: 0.16in 0 0.05in !important;
      color: var(--muted);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 7pt;
      font-weight: 700;
      letter-spacing: .12em;
      text-transform: uppercase;
    }
    .codebox {
      break-inside: avoid;
      margin: 0.14in 0 0.18in;
      overflow: hidden;
      border: 1px solid #0c2b44;
      border-radius: 7px;
      background: var(--blue-dark);
      box-shadow: 0 5px 14px rgba(24,55,78,.10);
    }
    .codebox figcaption {
      display: flex;
      align-items: center;
      justify-content: space-between;
      min-height: 0.30in;
      padding: 0.06in 0.11in;
      color: #a9c4d6;
      background: #0b2034;
      border-bottom: 1px solid #25435a;
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 6.6pt;
      font-weight: 600;
      letter-spacing: .12em;
    }
    .terminal-dots { display: flex; gap: 4px; }
    .terminal-dots i {
      display: block;
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--red);
    }
    .terminal-dots i:nth-child(2) { background: #ffc24b; }
    .terminal-dots i:nth-child(3) { background: #55c791; }
    .codebox pre {
      margin: 0;
      padding: 0.13in 0.15in 0.15in;
      color: #f0f7fb;
      background: transparent;
      font-family: 'Noto Sans Mono', 'DejaVu Sans Mono', monospace;
      font-size: 8.2pt;
      line-height: 1.43;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
      tab-size: 2;
      direction: ltr;
      unicode-bidi: plaintext;
      font-variant-ligatures: none;
      text-rendering: geometricPrecision;
    }
    .codebox pre code {
      padding: 0;
      border: 0;
      color: inherit;
      background: transparent;
      font: inherit;
    }
    .codebox--output {
      border-color: #cfdde4;
      background: #f3f7f9;
      box-shadow: none;
    }
    .codebox--output figcaption {
      color: #496174;
      background: #e5eef2;
      border-bottom-color: #cfdde4;
    }
    .codebox--output pre { color: #243d52; }
    article.chapter table {
      break-inside: avoid;
      width: 100%;
      margin: 0.14in 0 0.20in;
      overflow: hidden;
      border-collapse: separate;
      border-spacing: 0;
      border: 1px solid #cfdee5;
      border-radius: 7px;
      font-size: 8.4pt;
      line-height: 1.33;
    }
    article.chapter th {
      padding: 0.08in 0.09in;
      color: white;
      background: var(--blue);
      border-right: 1px solid rgba(255,255,255,.24);
      font-family: 'Poppins', Arial, sans-serif;
      font-size: 7.6pt;
      font-weight: 600;
      text-align: left;
    }
    article.chapter th:last-child { border-right: 0; }
    article.chapter td {
      padding: 0.07in 0.09in;
      border-top: 1px solid #dbe6eb;
      border-right: 1px solid #dbe6eb;
      vertical-align: top;
    }
    article.chapter td:last-child { border-right: 0; }
    article.chapter tbody tr:first-child td { border-top: 0; }
    article.chapter tbody tr:nth-child(even) td { background: #f6f9fa; }
    article.chapter blockquote {
      break-inside: avoid;
      margin: 0.14in 0;
      padding: 0.11in 0.14in;
      border-left: 4px solid var(--red);
      color: #45586a;
      background: #fff3f6;
    }
    article.chapter blockquote p:last-child { margin-bottom: 0; }
    article.chapter hr {
      margin: 0.26in 0;
      border: 0;
      border-top: 1px solid var(--line);
    }
    .closing .divider-number {
      color: white;
      background: var(--blue);
      border-color: var(--blue);
      font-size: 22pt;
    }
    .closing h2 { font-size: 30pt; }
    .closing-checks {
      display: grid;
      gap: 0.11in;
      max-width: 5.55in;
      margin-top: 0.32in;
    }
    .closing-checks div {
      display: flex;
      align-items: flex-start;
      gap: 0.11in;
      padding: 0.12in 0.15in;
      border: 1px solid #d2e0e7;
      border-radius: 7px;
      color: var(--blue-deep);
      background: #f7fafb;
      font-family: 'Montserrat', Arial, sans-serif;
      font-size: 9pt;
      line-height: 1.35;
    }
    .closing-checks div::before {
      content: '✓';
      display: grid;
      flex: 0 0 0.24in;
      width: 0.24in;
      height: 0.24in;
      place-items: center;
      border-radius: 50%;
      color: white;
      background: var(--red);
      font-family: Arial, sans-serif;
      font-size: 7.5pt;
      font-weight: 700;
    }
    .next-session {
      margin-top: 0.26in;
      color: var(--blue);
      font-size: 8.5pt;
      font-weight: 700;
      letter-spacing: .05em;
      text-transform: uppercase;
    }

    @media screen {
      body { background: #dde5e9; }
      .cover, .overview, .section-divider {
        margin: 20px auto;
        box-shadow: 0 12px 30px rgba(25,55,75,.14);
      }
      article.chapter {
        width: 7.1in;
        margin: 0 auto;
        padding: 0.76in 0 0.67in;
        background: white;
      }
      .page-furniture { display: none; }
    }
  </style>
</head>
<body>
  <svg class="svg-defs" aria-hidden="true" focusable="false">
    <defs>
      <clipPath id="rounded-chevron" clipPathUnits="objectBoundingBox">
        <path d="M 0 0 H .79 Q .815 0 .83 .03 L .992 .47 Q 1 .5 .992 .53 L .83 .97 Q .815 1 .79 1 H 0 Z"/>
      </clipPath>
      <clipPath id="rounded-hexagon" clipPathUnits="objectBoundingBox">
        <path d="M .19 0 H .81 Q .83 0 .84 .035 L .992 .47 Q 1 .5 .992 .53 L .84 .965 Q .83 1 .81 1 H .19 Q .17 1 .16 .965 L .008 .53 Q 0 .5 .008 .47 L .16 .035 Q .17 0 .19 0 Z"/>
      </clipPath>
      <clipPath id="rounded-bottom-panel" clipPathUnits="objectBoundingBox">
        <path d="M 0 0 H .65 Q .68 0 .70 .035 L .992 .965 Q 1 1 .96 1 H 0 Z"/>
      </clipPath>
      <clipPath id="rounded-slant-right" clipPathUnits="objectBoundingBox">
        <path d="M .30 0 H 1 V 1 H .03 Q 0 1 .018 .965 L .268 .035 Q .28 0 .30 0 Z"/>
      </clipPath>
      <clipPath id="rounded-slant-right-wide" clipPathUnits="objectBoundingBox">
        <path d="M .37 0 H 1 V 1 H .03 Q 0 1 .018 .965 L .338 .035 Q .35 0 .37 0 Z"/>
      </clipPath>
      <clipPath id="rounded-slant-left" clipPathUnits="objectBoundingBox">
        <path d="M 0 0 H .35 Q .38 0 .40 .035 L .992 .965 Q 1 1 .96 1 H 0 Z"/>
      </clipPath>
    </defs>
  </svg>
  <div class="page-furniture" aria-hidden="true">
    <div class="frame-border"></div>
    <div class="frame-top-blue"></div>
    <div class="frame-top-red"></div>
    <div class="frame-bottom-blue"></div>
    <div class="frame-bottom-red"></div>
    <div class="frame-brand">Linux desde cero</div>
    <div class="frame-footer">TecGurus · Clase 1 · Material del alumno</div>
  </div>

  <section class="cover">
    <div class="cover-top-shadow"></div>
    <div class="cover-top-panel"><div class="dots"></div></div>
    <img class="cover-logo" src="../shared/assets/tecgurus-logo.png" alt="TecGurus">
    <div class="cover-title">
      <div class="cover-kicker">Curso</div>
      <h1>Linux<br>Desde Cero</h1>
      <div class="cover-subtitle"><span class="class-pill">Clase 1</span> Fundamentos, archivos y permisos</div>
    </div>
    <div class="cover-url">www.tecgurus.net</div>
    <div class="cover-instructor"><span>Instructor</span>Ing. Abimael Domínguez</div>
    <div class="cover-bottom-panel"></div>
    <div class="photo-blue-back"></div>
    <div class="photo-red-back"></div>
    <img class="cover-photo" src="../shared/assets/portada-tecnologia.jpg" alt="Tecnología y archivos digitales">
    <div class="cover-hex-outline"></div>
  </section>

  <section class="overview">
    <header class="overview-header">
      <div class="overview-kicker">Agenda · 09:00–14:00</div>
      <h2>Clase 1 — Fundamentos, archivos y permisos</h2>
    </header>
    <div class="overview-files">
      <strong>Archivos:</strong> capítulos <span class="chapter-number">1</span>, <span class="chapter-number">3</span> y 7.1–7.15 de <span class="chapter-number">7</span>.
    </div>
    <table class="agenda-table" aria-label="Agenda de la clase 1">
      <thead><tr><th>Hora</th><th>Actividad</th></tr></thead>
      <tbody>${agendaRows}</tbody>
    </table>
    <div class="overview-foot">
      <div class="overview-note">
        <p><strong>No recortar:</strong> navegación, operaciones y permisos.</p>
        <p><strong>Recortar primero:</strong> comparación de distribuciones y detalles de cuentas.</p>
      </div>
    </div>
  </section>

  <section class="toc-page toc-single" id="indice-interactivo">
    <header class="toc-header">
      <div class="toc-kicker">Navegación · 1 de 2</div>
      <h2>Índice interactivo</h2>
      <p class="toc-description">Selecciona un apartado para ir directamente a su contenido. En cada encabezado encontrarás el enlace para volver aquí.</p>
    </header>
    <div class="toc-grid">${tocChapter1}</div>
    <nav class="toc-nav"><a href="#indice-interactivo-2">Capítulos 3 y 7 →</a></nav>
  </section>

  <section class="toc-page" id="indice-interactivo-2">
    <header class="toc-header">
      <div class="toc-kicker">Navegación · 2 de 2</div>
      <h2>Índice interactivo</h2>
      <p class="toc-description">Sistema de archivos y comandos esenciales del shell.</p>
    </header>
    <div class="toc-grid">${tocChapter3}${tocChapter7}</div>
    <nav class="toc-nav"><a href="#indice-interactivo">← Capítulo 1</a></nav>
  </section>

  <section class="section-divider" id="capitulo-1">
    <div class="divider-panel"><div class="divider-dots"></div></div>
    <div class="divider-red"></div><div class="divider-blue-foot"></div>
    <div class="divider-content">
      <div class="divider-number">01</div>
      <div class="divider-kicker">Fundamentos</div>
      <h2>Introducción a Linux</h2>
      <p class="divider-description">Kernel, distribución, terminal, shell, paquetes, usuarios, grupos y privilegios administrativos.</p>
      <div class="divider-tags"><span>Capítulo 1</span><span>Ubuntu 24.04</span><span>apt</span><span>sudo</span></div>
    </div>
  </section>
  <article class="chapter chapter-1">${chapter1}</article>

  <section class="section-divider" id="capitulo-3">
    <div class="divider-panel"><div class="divider-dots"></div></div>
    <div class="divider-red"></div><div class="divider-blue-foot"></div>
    <div class="divider-content">
      <div class="divider-number">02</div>
      <div class="divider-kicker">Sistema de archivos</div>
      <h2>Estructura, enlaces<br>y permisos</h2>
      <p class="divider-description">Tipos de archivo, rutas, jerarquía, montajes y el modelo de acceso para propietario, grupo y otros.</p>
      <div class="divider-tags"><span>Capítulo 3</span><span>FHS</span><span>chmod</span><span>chown</span></div>
    </div>
  </section>
  <article class="chapter chapter-3">${chapter3}</article>

  <section class="section-divider" id="capitulo-7">
    <div class="divider-panel"><div class="divider-dots"></div></div>
    <div class="divider-red"></div><div class="divider-blue-foot"></div>
    <div class="divider-content">
      <div class="divider-number">03</div>
      <div class="divider-kicker">Trabajo en terminal</div>
      <h2>El shell: comandos esenciales</h2>
      <p class="divider-description">Resolución de comandos, navegación y operaciones seguras con archivos hasta permisos y propiedad.</p>
      <div class="divider-tags"><span>Capítulo 7.1–7.15</span><span>bash</span><span>cp · mv · rm</span><span>file · stat</span></div>
    </div>
  </section>
  <article class="chapter chapter-7">${chapter7}</article>

  <section class="section-divider closing">
    <div class="divider-panel"><div class="divider-dots"></div></div>
    <div class="divider-red"></div><div class="divider-blue-foot"></div>
    <div class="divider-content">
      <div class="divider-number">✓</div>
      <div class="divider-kicker">Evidencia y cierre</div>
      <h2>Clase 1 completada</h2>
      <p class="divider-description">Al terminar la Clase 1, conserva una evidencia reproducible de tu sistema y de la estructura creada.</p>
      <div class="closing-checks">
        <div>Identifico distribución, kernel, usuario, grupos y shell activo.</div>
        <div>Navego y opero archivos con rutas, origen y destino claros.</div>
        <div>Interpreto enlaces, propietario, grupo y permisos antes de modificarlos.</div>
      </div>
      <div class="next-session">Siguiente: Clase 2 · Shell útil y escritorios</div>
    </div>
  </section>
</body>
</html>`;

fs.writeFileSync(outputFile, html);
console.log(outputFile);
