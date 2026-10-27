import { BookOpen, ChartColumn, ClipboardList, Image as ImageIcon, Presentation, Scale, Sparkles, Table2, Workflow } from 'lucide-react'

const caseIcons = {
  Table2,
  ChartColumn,
  ClipboardList,
  BookOpen,
  Presentation,
  Image: ImageIcon,
  Workflow,
  Scale,
}

export function caseIcon(item) {
  return caseIcons[item.icon] ?? Sparkles
}
