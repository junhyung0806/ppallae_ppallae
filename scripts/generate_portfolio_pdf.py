from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer


def parse_markdown(lines):
    story = []
    in_code = False
    code_lines = []
    styles = getSampleStyleSheet()
    heading_styles = {
        1: ParagraphStyle('Heading1', parent=styles['Heading1'], fontSize=22, leading=26, spaceAfter=12),
        2: ParagraphStyle('Heading2', parent=styles['Heading2'], fontSize=18, leading=22, spaceAfter=10),
        3: ParagraphStyle('Heading3', parent=styles['Heading3'], fontSize=14, leading=18, spaceAfter=8),
    }
    normal = ParagraphStyle('BodyText', parent=styles['BodyText'], spaceAfter=6)
    bullet = ParagraphStyle('Bullet', parent=styles['BodyText'], leftIndent=14, bulletIndent=0, spaceAfter=4)
    code_style = ParagraphStyle('Code', parent=styles['Code'], fontName='Courier', fontSize=9.5, leading=12, backColor=colors.whitesmoke, leftIndent=8, rightIndent=8, spaceAfter=6)

    def flush_code():
        nonlocal story, code_lines
        if code_lines:
            for line in code_lines:
                story.append(Paragraph(line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'), code_style))
            story.append(Spacer(1, 0.12 * inch))
            code_lines = []

    for raw in lines:
        line = raw.rstrip('\n')

        if line.startswith('```'):
            in_code = not in_code
            if not in_code:
                flush_code()
            continue

        if in_code:
            code_lines.append(line.replace(' ', '&nbsp;'))
            continue

        if not line.strip():
            story.append(Spacer(1, 0.12 * inch))
            continue

        if line.startswith('#'):
            level = len(line) - len(line.lstrip('#'))
            content = line.lstrip('#').strip()
            style = heading_styles.get(level, heading_styles[3])
            story.append(Paragraph(content, style))
            continue

        if line.startswith('- '):
            story.append(Paragraph(line[2:].strip(), bullet, bulletText='•'))
            continue

        if line.startswith('> '):
            quote = line[2:].strip()
            story.append(Paragraph(f'<i>{quote}</i>', normal))
            continue

        story.append(Paragraph(line, normal))

    flush_code()
    return story


def main():
    root = Path(__file__).resolve().parent.parent
    readme = root / 'README.md'
    arch = root / 'ARCHITECTURE.md'
    target = root / 'Ppallae_Portfolio_Documentation.pdf'

    content = []
    for path in [readme, arch]:
        if not path.exists():
            raise FileNotFoundError(f'Missing {path}')
        content.extend(path.read_text(encoding='utf-8').splitlines())
        content.append('')
        content.append('')

    doc = SimpleDocTemplate(str(target), pagesize=letter, rightMargin=0.75 * inch, leftMargin=0.75 * inch, topMargin=0.75 * inch, bottomMargin=0.75 * inch)
    story = parse_markdown(content)
    doc.build(story)
    print(f'Generated {target}')


if __name__ == '__main__':
    main()
