import { createRoot } from 'react-dom/client';

import HistoryPage, { type SiteLocale } from './history-page';
import './styles.css';

const rootElement = document.querySelector<HTMLElement>('#root');

if (!rootElement) {
  throw new Error('Missing #root element');
}

const locale: SiteLocale =
  rootElement.dataset.locale === 'en' ? 'en' : 'de';

document.documentElement.lang = locale;
createRoot(rootElement).render(<HistoryPage locale={locale} />);
