import {
  ArrowDown,
  ArrowUpRight,
  BatteryCharging,
  Bluetooth,
  Boxes,
  Cable,
  Check,
  CircleDot,
  Cpu,
  FolderGit,
  GitFork,
  Layers3,
  LockKeyhole,
  Network,
  Route,
  ShieldCheck,
  Sparkles,
  Usb,
  type LucideIcon,
} from 'lucide-react';

export type SiteLocale = 'de' | 'en';

const baseUrl = import.meta.env.BASE_URL;
const pageUrl = (path = '') => `${baseUrl}${path}`;
const assetUrl = (path: string) => `${baseUrl}${path}`;

type LocalizedText = Record<SiteLocale, string>;

const chapters: Array<{ href: string; label: LocalizedText }> = [
  { href: '#ursprung', label: { de: 'Ursprung', en: 'Origin' } },
  {
    href: '#menubarusb-tb',
    label: { de: 'MenuBarUSB-TB', en: 'MenuBarUSB-TB' },
  },
  { href: '#portglance', label: { de: 'PortGlance', en: 'PortGlance' } },
  { href: '#menubario', label: { de: 'MenuBarIO', en: 'MenuBarIO' } },
];

const eras: Array<{
  date: LocalizedText;
  label: LocalizedText;
  title: string;
  detail: LocalizedText;
  color: string;
}> = [
  {
    date: { de: '21.08.2026', en: '21 Aug 2026' },
    label: { de: 'Fork', en: 'Fork' },
    title: 'MenuBarUSB',
    detail: {
      de: 'MIT-lizenzierter Ausgangspunkt',
      en: 'MIT-licensed starting point',
    },
    color: '#f4b85a',
  },
  {
    date: { de: '21.–28.08.', en: '21–28 Aug' },
    label: { de: 'Ausbau', en: 'Expansion' },
    title: 'MenuBarUSB-TB',
    detail: {
      de: 'Thunderbolt, USB4 & Universal',
      en: 'Thunderbolt, USB4 & Universal',
    },
    color: '#47b0b4',
  },
  {
    date: { de: '30.–31.08.', en: '30–31 Aug' },
    label: { de: 'Eigenständig', en: 'Independent' },
    title: 'PortGlance',
    detail: {
      de: 'Native UI & echte Topologie',
      en: 'Native UI & real topology',
    },
    color: '#46a9d7',
  },
  {
    date: { de: '31.08.2026', en: '31 Aug 2026' },
    label: { de: 'Heute', en: 'Today' },
    title: 'MenuBarIO',
    detail: {
      de: 'Lokaler Hardware-Inspektor',
      en: 'Local hardware inspector',
    },
    color: '#8872ff',
  },
];

type Milestone = {
  id?: string;
  date: LocalizedText;
  version: string;
  era: LocalizedText;
  title: LocalizedText;
  body: LocalizedText;
  bullets: Array<LocalizedText>;
  icon: LucideIcon;
  color: string;
};

const milestones: Array<Milestone> = [
  {
    id: 'menubarusb-tb',
    date: { de: '21. August 2026', en: '21 August 2026' },
    version: 'v0.1.0 · v0.1.1',
    era: { de: 'MenuBarUSB-TB', en: 'MenuBarUSB-TB' },
    title: {
      de: 'Der Fork bekommt eine klare Aufgabe.',
      en: 'The fork gets a clear purpose.',
    },
    body: {
      de: 'Aus dem MenuBarUSB-Quellstand entsteht ein unabhängiger, lokaler Hardware-Inspektor. Thunderbolt- und USB4-Geräte werden neben USB über IOKit erkannt – samt Protokoll und ausgehandelter Link-Geschwindigkeit.',
      en: 'The MenuBarUSB codebase becomes an independent, local hardware inspector. Thunderbolt and USB4 devices are now discovered alongside USB through IOKit — including protocol and negotiated link speed.',
    },
    bullets: [
      {
        de: 'USB-Geräte und reine Hubs in getrennten, einklappbaren Gruppen',
        en: 'USB devices and pure hubs in separate, collapsible groups',
      },
      {
        de: 'Keine doppelten Dock-Einträge durch USB-C-Billboard-Schnittstellen',
        en: 'No duplicate dock entries from USB-C Billboard interfaces',
      },
      {
        de: 'Entfernung von Sounds, Spendenfunktionen, Telemetrie und Update-Abfragen',
        en: 'Removal of sounds, donation features, telemetry and update checks',
      },
      {
        de: 'Signierter, notarisierter Apple-Silicon-Release mit geführtem DMG',
        en: 'Signed and notarized Apple Silicon release with a guided DMG',
      },
    ],
    icon: GitFork,
    color: '#f4b85a',
  },
  {
    date: { de: '25. August 2026', en: '25 August 2026' },
    version: 'v0.1.2',
    era: { de: 'Universal', en: 'Universal' },
    title: {
      de: 'Zwei Architekturen, dieselbe lokale Grenze.',
      en: 'Two architectures, the same local boundary.',
    },
    body: {
      de: 'MenuBarUSB-TB wird zur Universal-App für Apple Silicon und Intel. Gleichzeitig werden Ereignisverarbeitung, Berechtigungen und die Release-Prüfung deutlich strenger.',
      en: 'MenuBarUSB-TB becomes a Universal app for Apple Silicon and Intel. At the same time, event handling, entitlements and release verification become considerably stricter.',
    },
    bullets: [
      {
        de: 'Native Builds für arm64 und x86_64 ab macOS 13',
        en: 'Native builds for arm64 and x86_64 on macOS 13 or later',
      },
      {
        de: 'CI-Tests auf beiden Architekturen',
        en: 'CI tests on both architectures',
      },
      {
        de: 'Nur noch Sandbox- und USB-Geräteberechtigung',
        en: 'Only sandbox and USB-device entitlements remain',
      },
      {
        de: 'Stabilere Aktualisierung bei USB-, Thunderbolt- und USB4-Ereignissen',
        en: 'More reliable refresh handling for USB, Thunderbolt and USB4 events',
      },
    ],
    icon: Cpu,
    color: '#47b0b4',
  },
  {
    date: { de: '26. August 2026', en: '26 August 2026' },
    version: 'v0.1.3',
    era: { de: 'Mehr Kontext', en: 'More context' },
    title: {
      de: 'Bluetooth und interne Geräte kommen hinzu.',
      en: 'Bluetooth and internal devices are added.',
    },
    body: {
      de: 'Die Menüleisten-App zeigt nun verbundene Bluetooth-Geräte und trennt integrierte Mac-Hardware sichtbar von externen Geräten. Die Oberfläche wird zugleich mehrsprachig und notebook-tauglicher.',
      en: 'The menu-bar app now shows connected Bluetooth devices and visibly separates built-in Mac hardware from external devices. At the same time, the interface becomes multilingual and better suited to notebooks.',
    },
    bullets: [
      {
        de: 'Bluetooth-Status als eigene Gerätegruppe',
        en: 'Bluetooth status as a dedicated device group',
      },
      {
        de: 'Interne Komponenten beeinflussen den externen Gerätezähler nicht',
        en: 'Internal components do not affect the external-device count',
      },
      {
        de: 'App-Sprachauswahl mit automatischer macOS-Vorgabe',
        en: 'App language selector with automatic macOS default',
      },
      {
        de: 'Erste gezielte Beobachtungen auf einem Intel-MacBook',
        en: 'First focused observations on an Intel MacBook',
      },
    ],
    icon: Bluetooth,
    color: '#53b3c0',
  },
  {
    date: { de: '28. August 2026', en: '28 August 2026' },
    version: 'v0.1.4',
    era: { de: 'Fundament', en: 'Foundation' },
    title: {
      de: 'Aus einem großen Manager werden klare Systemdienste.',
      en: 'One large manager becomes focused system services.',
    },
    body: {
      de: 'Die interne Architektur wird neu geordnet: Erkennung, Verbindungsereignisse, Stromquellen und Ethernet erhalten eigene Verantwortungsbereiche. Geräte behalten über Aktualisierungen hinweg ihre stabile Identität.',
      en: 'The internal architecture is reorganized: discovery, connection events, power sources and Ethernet receive focused responsibilities. Devices retain a stable identity across refreshes.',
    },
    bullets: [
      {
        de: 'Stabile Gerätezeilen und erhaltene Aufklappzustände',
        en: 'Stable device rows and preserved expanded state',
      },
      {
        de: 'Gemeinsame Bedienelemente für aktuelle und klassische Einstellungen',
        en: 'Shared controls for current and classic settings',
      },
      {
        de: 'Gezielte Unit-Tests, Format- und Lokalisierungsprüfungen',
        en: 'Focused unit tests, formatting and localization checks',
      },
      {
        de: 'Strenge Prüfung der Notarisierungs-Tickets von App und DMG',
        en: 'Strict verification of notarization tickets for the app and DMG',
      },
    ],
    icon: Boxes,
    color: '#5aa7d0',
  },
  {
    id: 'portglance',
    date: { de: '30. August 2026', en: '30 August 2026' },
    version: 'v0.2.0',
    era: { de: 'PortGlance', en: 'PortGlance' },
    title: {
      de: 'Der technische Fork wird ein eigenes Produkt.',
      en: 'The technical fork becomes its own product.',
    },
    body: {
      de: 'App, Xcode-Projekt, Targets und Release-Kanal heißen jetzt PortGlance. Ein neues Icon und native SF Symbols geben der Anwendung eine eigenständige, konsistente macOS-Identität.',
      en: 'The app, Xcode project, targets and release channel are now named PortGlance. A new icon and native SF Symbols give the application an independent, consistent macOS identity.',
    },
    bullets: [
      {
        de: 'Eigener Name, App-Icon und kanonisches Repository',
        en: 'Independent name, app icon and canonical repository',
      },
      {
        de: 'Native Symbole statt historischer eigener Grafiksets',
        en: 'Native symbols replace the historical custom graphic sets',
      },
      {
        de: 'Bestehende Installationen behalten Einstellungen und Login-Identität',
        en: 'Existing installations retain settings and login-item identity',
      },
      {
        de: 'Geräteerkennung und lokales Datenschutzmodell bleiben unverändert',
        en: 'Device discovery and the local privacy model remain unchanged',
      },
    ],
    icon: Sparkles,
    color: '#46a9d7',
  },
  {
    date: { de: '31. August 2026', en: '31 August 2026' },
    version: 'v0.2.1',
    era: { de: 'Native Reduktion', en: 'Native reduction' },
    title: {
      de: 'Weniger Einstellungen, mehr Klarheit.',
      en: 'Fewer settings, greater clarity.',
    },
    body: {
      de: 'PortGlance wird bewusst kleiner. Die Menüleiste zeigt feste USB- und Bluetooth-Symbole, die Geräteliste nützliche Informationen ohne Konfigurationsballast, und die Einstellungen passen in eine kompakte native Ansicht.',
      en: 'PortGlance deliberately becomes smaller. The menu bar shows fixed USB and Bluetooth symbols, the device list presents useful information without configuration overhead, and the settings fit into one compact native view.',
    },
    bullets: [
      {
        de: 'Dezimale Zähler mit kompakter 99＋-Darstellung',
        en: 'Decimal counters with a compact 99＋ cap',
      },
      {
        de: 'System-, Hell- und Dunkelmodus für das tatsächliche Host-Fenster',
        en: 'System, Light and Dark appearance for the actual host window',
      },
      {
        de: 'Native macOS-Schalter und direkte, handlungsorientierte Beschriftungen',
        en: 'Native macOS switches and direct, action-oriented labels',
      },
      {
        de: 'Konsequente Migration und Entfernung aufgegebener Optionen',
        en: 'Thorough migration and removal of retired options',
      },
    ],
    icon: Layers3,
    color: '#4a91de',
  },
  {
    date: { de: '31. August 2026', en: '31 August 2026' },
    version: 'v0.3.0',
    era: { de: 'Topologie', en: 'Topology' },
    title: {
      de: 'Ports werden wichtiger als bloße Gerätelisten.',
      en: 'Ports become more important than simple device lists.',
    },
    body: {
      de: 'Die App modelliert jetzt die physische USB-/Thunderbolt-Topologie: Host-Ports, freie Anschlüsse, native Geräte und nachgelagerte Dock-Ports werden dort gezeigt, wo sie tatsächlich hängen.',
      en: 'The app now models the physical USB and Thunderbolt topology: host ports, free connectors, native devices and downstream dock ports are shown where they are actually attached.',
    },
    bullets: [
      {
        de: 'Alle physischen Thunderbolt-/USB4-Host-Ports mit Status und Geschwindigkeit',
        en: 'Every physical Thunderbolt/USB4 host port with status and speed',
      },
      {
        de: 'Tunneled USB-Hubs unter ihrem nachweisbaren Thunderbolt-Besitzer',
        en: 'Tunneled USB hubs under their proven Thunderbolt owner',
      },
      {
        de: 'Thunderbolt-Geräte nur noch an ihrem physischen Port statt doppelt',
        en: 'Thunderbolt devices only at their physical port instead of duplicated',
      },
      {
        de: 'Validierung am M4 Pro Mac mini mit Docks, SSDs und Live-Wechseln',
        en: 'Validation on an M4 Pro Mac mini with docks, SSDs and live changes',
      },
    ],
    icon: Route,
    color: '#657fe7',
  },
  {
    date: { de: '31. August 2026', en: '31 August 2026' },
    version: 'v0.4.0',
    era: { de: 'Hardware-Wahrheit', en: 'Hardware truth' },
    title: {
      de: 'Eindeutig zuordnen – oder bewusst offenlassen.',
      en: 'Assign with certainty — or deliberately leave it open.',
    },
    body: {
      de: 'DROM-Port-Maps, USB-Elternpfade und Tunnel-Topologie werden kombiniert, ohne aus unsicheren Signalen Gewissheit zu erfinden. Auf Intel-/T2-MacBooks kommen Stromanschluss-Belegung und echte Batterieladeleistung hinzu.',
      en: 'DROM port maps, USB parent paths and tunnel topology are combined without inventing certainty from uncertain signals. On Intel/T2 MacBooks, power-only port occupancy and real battery charging power are added.',
    },
    bullets: [
      {
        de: 'USB-Geräte an Dock-Ports nur bei genau einer belegbaren Zuordnung',
        en: 'USB devices on dock ports only when exactly one assignment is proven',
      },
      {
        de: 'Unklare Hub-Zuordnung bleibt ausdrücklich „unbekannt“',
        en: 'Ambiguous hub ownership remains explicitly “unknown”',
      },
      {
        de: 'Power-only USB-C-Ports ohne Überschreiben echter Datenbelegung',
        en: 'Power-only USB-C ports without replacing real data occupancy',
      },
      {
        de: 'Physische Abnahme auf Apple Silicon und Intel/T2 · 64 Tests',
        en: 'Physical acceptance on Apple Silicon and Intel/T2 · 64 tests',
      },
    ],
    icon: BatteryCharging,
    color: '#786fe8',
  },
  {
    id: 'menubario',
    date: { de: '31. August 2026', en: '31 August 2026' },
    version: 'v0.5.0',
    era: { de: 'MenuBarIO', en: 'MenuBarIO' },
    title: {
      de: 'Der Name beschreibt, was daraus geworden ist.',
      en: 'The name describes what it has become.',
    },
    body: {
      de: 'MenuBarIO bündelt die Herkunft als Menüleisten-App und den erweiterten Blick auf Ein- und Ausgabe-Hardware. Der neue Produktname verändert nicht die bewährte Erkennung – er gibt ihr den passenden Rahmen.',
      en: 'MenuBarIO combines its menu-bar origins with an expanded view of input and output hardware. The new product name does not change the proven discovery logic — it gives it the right frame.',
    },
    bullets: [
      {
        de: 'USB-, Thunderbolt-, USB4- & Bluetooth-Inspektor für macOS',
        en: 'USB, Thunderbolt, USB4 & Bluetooth inspector for macOS',
      },
      {
        de: 'Universelle App für Apple Silicon und Intel ab macOS 13',
        en: 'Universal app for Apple Silicon and Intel on macOS 13 or later',
      },
      {
        de: 'Lokale Geräte- und Strominformationen ohne Netzwerk-Client-Code',
        en: 'Local device and power information without network client code',
      },
      {
        de: 'Signierter, notarisierter und stapled Universal-Release',
        en: 'Signed, notarized and stapled Universal release',
      },
    ],
    icon: CircleDot,
    color: '#8872ff',
  },
];

const releases = [
  ['0.1.0', '21.08.'],
  ['0.1.1', '21.08.'],
  ['0.1.2', '25.08.'],
  ['0.1.3', '26.08.'],
  ['0.1.4', '28.08.'],
  ['0.2.0', '30.08.'],
  ['0.2.1', '31.08.'],
  ['0.3.0', '31.08.'],
  ['0.4.0', '31.08.'],
  ['0.5.0', '31.08.'],
];

const copy = {
  navLabel: {
    de: 'Hauptnavigation',
    en: 'Primary navigation',
  },
  homeLabel: {
    de: 'MenuBarIO Projektverlauf – Start',
    en: 'MenuBarIO project history – Home',
  },
  repository: { de: 'Repository', en: 'Repository' },
  languageLabel: { de: 'Sprache wählen', en: 'Choose language' },
  heroKicker: {
    de: 'Vom MIT-lizenzierten Ursprung zur eigenen Produktidentität',
    en: 'From an MIT-licensed origin to an independent product identity',
  },
  heroLineOne: { de: 'Vier Namen.', en: 'Four names.' },
  heroLineTwo: { de: 'Eine klare Linie.', en: 'One clear line.' },
  heroBody: {
    de: 'Wie aus einem fokussierten MenuBarUSB-Fork ein präziser, lokaler Inspektor für die echte Hardware-Topologie des Mac wurde.',
    en: 'How a focused MenuBarUSB fork became a precise, local inspector for the Mac’s real hardware topology.',
  },
  explore: { de: 'Verlauf entdecken', en: 'Explore the journey' },
  development: { de: 'Entwicklung', en: 'Development' },
  days: { de: '10 Tage', en: '10 days' },
  releases: { de: 'Releases', en: 'Releases' },
  architectures: { de: 'Architekturen', en: 'Architectures' },
  localSummary: {
    de: 'Unabhängig entwickelt · lokal auf dem Mac · ohne Telemetrie',
    en: 'Independently developed · local on the Mac · no telemetry',
  },
  asOf: { de: 'Stand: 31. August 2026', en: 'As of 31 August 2026' },
  originEyebrow: { de: 'Der Ausgangspunkt', en: 'The starting point' },
  originTitle: {
    de: 'Herkunft bewahren. Richtung selbst bestimmen.',
    en: 'Preserve the origin. Define the direction.',
  },
  originBody: {
    de: 'MenuBarIO begann mit dem öffentlich verfügbaren, MIT-lizenzierten Quellcode von',
    en: 'MenuBarIO began with the publicly available, MIT-licensed source code of',
  },
  originAfterLink: {
    de: 'Idee, Urheberschaft und Copyright-Hinweis bleiben sichtbar – die weitere Entwicklung ist jedoch vollständig unabhängig.',
    en: 'The original idea, authorship and copyright notice remain visible — but all further development is entirely independent.',
  },
  motivationBody: {
    de: 'Der konkrete Anstoß für die Anpassung kam aus zwei Lücken im damaligen Stand: Die App wurde weder mit einer Developer-ID signiert noch von Apple notarisiert ausgeliefert. Dadurch waren Installation und Vertrauen unter den aktuellen macOS-Schutzmechanismen unnötig erschwert. Gleichzeitig fehlte die Unterstützung für Thunderbolt und USB4, sodass ein wesentlicher Teil moderner Mac-Anschlüsse und Dock-Topologien unsichtbar blieb. Das Ziel war deshalb von Anfang an, die vorhandene Idee vertrauenswürdig auslieferbar zu machen und ihren Blick von USB auf die tatsächlich genutzte I/O-Landschaft moderner Macs zu erweitern.',
    en: 'The concrete motivation for adapting the app came from two gaps in its state at the time: it was distributed without a Developer ID signature or Apple notarization. That made installation and trust unnecessarily difficult under modern macOS security protections. At the same time, Thunderbolt and USB4 support were missing, leaving an essential part of modern Mac ports and dock topologies invisible. From the outset, the goal was therefore to make the existing idea trustworthy to distribute and to expand its view from USB to the I/O landscape actually used by modern Macs.',
  },
  independentTitle: {
    de: 'Unabhängige Weiterentwicklung',
    en: 'Independent development',
  },
  independentBody: {
    de: 'MenuBarIO ist weder offizieller Nachfolger noch offizielle Fortführung oder bestätigte Variante von MenuBarUSB. Es besteht keine Zusammenarbeit oder Zugehörigkeit; der ursprüngliche Autor ist an Entwicklung, Pflege, Support und Releases nicht beteiligt.',
    en: 'MenuBarIO is neither an official successor nor an official continuation or endorsed version of MenuBarUSB. There is no collaboration or affiliation; the original author is not involved in development, maintenance, support or releases.',
  },
  journeyEyebrow: { de: 'Die Entwicklung', en: 'The journey' },
  journeyTitle: {
    de: 'Die entscheidenden Schritte.',
    en: 'The defining steps.',
  },
  journeyBody: {
    de: 'Nicht jede Änderung war ein neues Feature. Der rote Faden ist eine Folge aus Reduktion, belastbarer Hardware-Erkennung und immer strengeren Prüfungen.',
    en: 'Not every change was a new feature. The common thread is a sequence of reduction, reliable hardware discovery and increasingly strict verification.',
  },
  changesIn: { de: 'Änderungen in', en: 'Changes in' },
  principlesEyebrow: { de: 'Was konstant blieb', en: 'What remained constant' },
  principlesTitle: {
    de: 'Drei Prinzipien über alle Namen hinweg.',
    en: 'Three principles across every name.',
  },
  localTitle: { de: 'Lokal', en: 'Local' },
  localBody: {
    de: 'Keine Telemetrie, keine Analyse, keine Update-Abfragen und kein Netzwerk-Client-Code.',
    en: 'No telemetry, analytics, update checks or network client code.',
  },
  evidenceTitle: { de: 'Belegbar', en: 'Evidence-based' },
  evidenceBody: {
    de: 'Topologie wird nur dort zugeordnet, wo IOKit und Hardwarebeobachtung eindeutige Signale liefern.',
    en: 'Topology is assigned only where IOKit and physical hardware observations provide unambiguous evidence.',
  },
  universalTitle: { de: 'Universal', en: 'Universal' },
  universalBody: {
    de: 'Apple Silicon und Intel, automatisiert geprüft und auf realer Hardware nachvollzogen.',
    en: 'Apple Silicon and Intel, checked automatically and verified on real hardware.',
  },
  releaseEyebrow: { de: 'Release-Linie', en: 'Release line' },
  releaseTitle: {
    de: 'Zehn Stationen. Eine Codebasis.',
    en: 'Ten milestones. One codebase.',
  },
  allReleases: { de: 'Alle Releases', en: 'All releases' },
  publishedVersions: {
    de: 'Veröffentlichte Versionen',
    en: 'Published versions',
  },
  finalEyebrow: { de: 'MenuBarIO · v0.5.0', en: 'MenuBarIO · v0.5.0' },
  finalTitle: {
    de: 'Der aktuelle Name. Die gewachsene Präzision.',
    en: 'The current name. The precision built over time.',
  },
  finalBody: {
    de: 'Heute ist MenuBarIO ein nativer Universal-Inspektor für USB, Thunderbolt, USB4 und Bluetooth – kompakt in der Menüleiste, detailliert bei der Topologie und konsequent lokal.',
    en: 'Today, MenuBarIO is a native Universal inspector for USB, Thunderbolt, USB4 and Bluetooth — compact in the menu bar, detailed in its topology and consistently local.',
  },
  openRepository: { de: 'Repository öffnen', en: 'Open repository' },
  releaseLabel: { de: 'Release v0.5.0', en: 'Release v0.5.0' },
  footer: {
    de: 'Projektverlauf auf Basis der erhaltenen Git-Historie und Release-Dokumentation · Stand 31.08.2026',
    en: 'Project history based on the preserved Git history and release documentation · As of 31 August 2026',
  },
  backToTop: { de: 'Nach oben', en: 'Back to top' },
} satisfies Record<string, LocalizedText>;

export default function HistoryPage({ locale }: { locale: SiteLocale }) {
  const t = (value: LocalizedText) => value[locale];
  const isGerman = locale === 'de';

  return (
    <main lang={locale} className="min-h-screen overflow-hidden bg-background text-foreground">
      <section className="hero-shell relative isolate mx-auto flex min-h-screen max-w-[1500px] flex-col px-5 pb-10 pt-5 sm:px-8 lg:px-12">
        <div className="grid-glow" aria-hidden="true" />

        <nav
          className="relative z-20 flex items-center justify-between border-b border-white/10 pb-5"
          aria-label={t(copy.navLabel)}
        >
          <a
            href="#top"
            className="flex items-center gap-3"
            aria-label={t(copy.homeLabel)}
          >
            <img
              src={assetUrl('menubario-icon.png')}
              alt="MenuBarIO App Icon"
              className="h-10 w-10 rounded-[12px] shadow-[0_10px_28px_rgba(0,0,0,.35)]"
            />
            <span className="text-sm font-semibold tracking-[-0.02em]">MenuBarIO</span>
          </a>

          <div className="hidden items-center gap-1 lg:flex">
            {chapters.map((chapter) => (
              <a
                key={chapter.href}
                href={chapter.href}
                className="rounded-full px-3 py-2 text-xs text-[#8e9bad] transition hover:bg-white/[0.05] hover:text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#f4b85a]"
              >
                {t(chapter.label)}
              </a>
            ))}
          </div>

          <div className="flex items-center gap-2 sm:gap-3">
            <div
              className="flex items-center rounded-full border border-white/10 bg-white/[0.035] p-1 font-mono text-[10px] font-semibold tracking-[0.08em]"
              aria-label={t(copy.languageLabel)}
            >
              {isGerman ? (
                <>
                  <span aria-current="page" className="rounded-full bg-white px-2.5 py-1.5 text-[#10141c]">DE</span>
                  <a href={pageUrl('en/')} hrefLang="en" lang="en" className="rounded-full px-2.5 py-1.5 text-[#93a0b2] transition hover:text-white">EN</a>
                </>
              ) : (
                <>
                  <a href={pageUrl()} hrefLang="de" lang="de" className="rounded-full px-2.5 py-1.5 text-[#93a0b2] transition hover:text-white">DE</a>
                  <span aria-current="page" className="rounded-full bg-white px-2.5 py-1.5 text-[#10141c]">EN</span>
                </>
              )}
            </div>

            <a
              href="https://github.com/r3d42-git/MenuBarIO"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.035] px-3.5 py-2 text-xs font-medium text-[#bec7d4] transition hover:border-white/20 hover:bg-white/[0.07] hover:text-white focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#f4b85a]"
            >
              <FolderGit className="h-3.5 w-3.5" />
              <span className="hidden sm:inline">{t(copy.repository)}</span>
              <ArrowUpRight className="h-3 w-3" />
            </a>
          </div>
        </nav>

        <div
          id="top"
          className="relative z-10 grid flex-1 items-center gap-12 py-14 lg:grid-cols-[minmax(0,1.02fr)_minmax(560px,.98fr)] lg:py-16"
        >
          <div className="max-w-3xl">
            <div className="mb-8 flex items-center gap-2 text-xs font-medium text-[#9ca9ba]">
              <GitFork className="h-4 w-4 text-[#f5b955]" />
              <span>{t(copy.heroKicker)}</span>
            </div>

            <h1 className="text-balance text-[clamp(3.6rem,8vw,7.5rem)] font-semibold leading-[.83] tracking-[-0.072em]">
              {t(copy.heroLineOne)}
              <span className="mt-2 block text-[#f4b85a]">{t(copy.heroLineTwo)}</span>
            </h1>

            <p className="mt-8 max-w-xl text-pretty text-base leading-7 text-[#aeb8c7] sm:text-lg sm:leading-8">
              {t(copy.heroBody)}
            </p>

            <div className="mt-10 flex flex-wrap items-center gap-3">
              <a
                href="#ursprung"
                className="inline-flex h-11 items-center gap-2 rounded-full bg-[#f4b85a] px-5 text-sm font-semibold text-[#17130d] transition hover:bg-[#ffd17f] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-[#f4b85a]"
              >
                {t(copy.explore)} <ArrowDown className="h-4 w-4" />
              </a>
              <div className="flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.035] px-4 py-2.5 text-xs text-[#aeb8c7]">
                <Usb className="h-4 w-4" />
                <Cable className="h-4 w-4" />
                <Bluetooth className="h-4 w-4" />
                <span className="ml-1">USB · TB/USB4 · Bluetooth</span>
              </div>
            </div>

            <dl className="mt-12 grid max-w-xl grid-cols-3 border-y border-white/10 py-5">
              <div>
                <dt className="text-[10px] uppercase tracking-[0.16em] text-[#6f7b8c]">{t(copy.development)}</dt>
                <dd className="mt-1 text-2xl font-semibold tracking-[-0.04em]">{t(copy.days)}</dd>
              </div>
              <div className="border-l border-white/10 pl-5">
                <dt className="text-[10px] uppercase tracking-[0.16em] text-[#6f7b8c]">{t(copy.releases)}</dt>
                <dd className="mt-1 text-2xl font-semibold tracking-[-0.04em]">10</dd>
              </div>
              <div className="border-l border-white/10 pl-5">
                <dt className="text-[10px] uppercase tracking-[0.16em] text-[#6f7b8c]">{t(copy.architectures)}</dt>
                <dd className="mt-1 text-2xl font-semibold tracking-[-0.04em]">2</dd>
              </div>
            </dl>
          </div>

          <div className="relative mx-auto w-full max-w-2xl">
            <div
              className="absolute bottom-8 left-[9px] top-8 w-px bg-gradient-to-b from-[#f5b955] via-[#46a9d7] to-[#8872ff] opacity-70 sm:left-1/2"
              aria-hidden="true"
            />
            <div className="space-y-4">
              {eras.map((era, index) => (
                <article
                  key={era.title}
                  className={`timeline-card relative ml-8 rounded-[22px] border border-white/10 bg-[#101720]/90 p-5 backdrop-blur sm:ml-0 sm:w-[calc(50%-24px)] ${
                    index % 2 === 0 ? 'sm:mr-auto' : 'sm:ml-auto'
                  }`}
                >
                  <span
                    className={`absolute top-7 h-[11px] w-[11px] rounded-full border-2 border-[#0a0f16] shadow-[0_0_0_4px_rgba(255,255,255,.04)] ${
                      index % 2 === 0
                        ? '-left-[30px] sm:-right-[30px] sm:left-auto'
                        : '-left-[30px]'
                    }`}
                    style={{ background: era.color }}
                    aria-hidden="true"
                  />
                  <div className="flex items-center justify-between gap-4">
                    <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-[#768397]">{t(era.date)}</p>
                    <span className="rounded-full border border-white/10 px-2 py-1 text-[9px] uppercase tracking-[0.14em] text-[#738094]">{t(era.label)}</span>
                  </div>
                  <h2 className="mt-3 text-xl font-semibold tracking-[-0.035em]">{era.title}</h2>
                  <p className="mt-2 text-sm leading-6 text-[#9ca9ba]">{t(era.detail)}</p>
                </article>
              ))}
            </div>
          </div>
        </div>

        <div className="relative z-10 flex flex-col gap-2 border-t border-white/10 pt-5 text-xs text-[#6f7b8c] sm:flex-row sm:items-center sm:justify-between">
          <span>{t(copy.localSummary)}</span>
          <span>{t(copy.asOf)}</span>
        </div>
      </section>

      <section id="ursprung" className="relative border-y border-white/10 bg-[#0d141d] px-5 py-24 sm:px-8 lg:px-12">
        <div className="mx-auto grid max-w-7xl gap-12 lg:grid-cols-[.8fr_1.2fr] lg:gap-20">
          <div>
            <p className="eyebrow">{t(copy.originEyebrow)}</p>
            <h2 className="mt-4 max-w-md text-balance text-4xl font-semibold tracking-[-0.055em] sm:text-5xl">{t(copy.originTitle)}</h2>
          </div>
          <div className="space-y-7 text-base leading-8 text-[#aeb8c7]">
            <p>
              {t(copy.originBody)}{' '}
              <a
                className="text-white underline decoration-white/25 underline-offset-4 hover:decoration-white"
                href="https://github.com/rafaelSwi/MenuBarUSB"
                target="_blank"
                rel="noreferrer"
              >
                rafaelSwi/MenuBarUSB
              </a>
              . {t(copy.originAfterLink)}
            </p>
            <p>{t(copy.motivationBody)}</p>
            <div className="rounded-[24px] border border-[#f4b85a]/20 bg-[#f4b85a]/[0.055] p-6 sm:p-7">
              <div className="flex gap-4">
                <ShieldCheck className="mt-1 h-5 w-5 shrink-0 text-[#f4b85a]" />
                <div>
                  <h3 className="font-semibold text-white">{t(copy.independentTitle)}</h3>
                  <p className="mt-2 text-sm leading-6 text-[#aeb8c7]">{t(copy.independentBody)}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="px-5 py-24 sm:px-8 lg:px-12 lg:py-32">
        <div className="mx-auto max-w-7xl">
          <div className="grid gap-8 border-b border-white/10 pb-12 lg:grid-cols-[.8fr_1.2fr]">
            <div>
              <p className="eyebrow">{t(copy.journeyEyebrow)}</p>
              <h2 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.055em] sm:text-5xl">{t(copy.journeyTitle)}</h2>
            </div>
            <p className="max-w-2xl self-end text-base leading-8 text-[#9ca9ba]">{t(copy.journeyBody)}</p>
          </div>

          <div className="relative mt-16">
            <div
              className="absolute bottom-0 left-[15px] top-0 w-px bg-gradient-to-b from-[#f4b85a] via-[#46a9d7] to-[#8872ff] opacity-35 md:left-1/2"
              aria-hidden="true"
            />
            <div className="space-y-10 md:space-y-16">
              {milestones.map((item, index) => {
                const Icon = item.icon;
                return (
                  <article
                    key={item.version}
                    id={item.id}
                    className={`milestone relative ml-12 scroll-mt-8 md:ml-0 md:grid md:grid-cols-2 md:gap-20 ${
                      index % 2 === 0 ? '' : 'md:[&>div]:col-start-2'
                    }`}
                  >
                    <span
                      className="absolute -left-[41px] top-7 z-10 grid h-8 w-8 place-items-center rounded-full border border-white/10 bg-[#111925] md:left-1/2 md:-translate-x-1/2"
                      aria-hidden="true"
                    >
                      <Icon className="h-3.5 w-3.5" style={{ color: item.color }} />
                    </span>
                    <div
                      className={`rounded-[26px] border border-white/10 bg-[#101720]/78 p-6 shadow-[0_24px_70px_rgba(0,0,0,.16)] sm:p-8 ${
                        index % 2 === 0 ? 'md:pr-9' : 'md:pl-9'
                      }`}
                    >
                      <div className="flex flex-wrap items-center justify-between gap-3">
                        <time className="font-mono text-[10px] uppercase tracking-[0.16em] text-[#78869a]">{t(item.date)}</time>
                        <span
                          className="rounded-full border border-white/10 px-2.5 py-1 font-mono text-[9px] uppercase tracking-[0.14em]"
                          style={{ color: item.color }}
                        >
                          {item.version}
                        </span>
                      </div>
                      <p className="mt-6 text-xs font-semibold uppercase tracking-[0.14em]" style={{ color: item.color }}>{t(item.era)}</p>
                      <h3 className="mt-2 text-balance text-2xl font-semibold tracking-[-0.045em] sm:text-3xl">{t(item.title)}</h3>
                      <p className="mt-4 text-sm leading-7 text-[#9ca9ba]">{t(item.body)}</p>
                      <ul className="mt-6 space-y-3" aria-label={`${t(copy.changesIn)} ${item.version}`}>
                        {item.bullets.map((bullet) => (
                          <li key={t(bullet)} className="flex gap-3 text-sm leading-6 text-[#bec7d4]">
                            <Check className="mt-1 h-3.5 w-3.5 shrink-0" style={{ color: item.color }} />
                            <span>{t(bullet)}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </article>
                );
              })}
            </div>
          </div>
        </div>
      </section>

      <section className="border-y border-white/10 bg-[#0d141d] px-5 py-24 sm:px-8 lg:px-12">
        <div className="mx-auto max-w-7xl">
          <div className="grid gap-8 lg:grid-cols-[.8fr_1.2fr]">
            <div>
              <p className="eyebrow">{t(copy.principlesEyebrow)}</p>
              <h2 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.055em] sm:text-5xl">{t(copy.principlesTitle)}</h2>
            </div>
            <div className="grid gap-px overflow-hidden rounded-[26px] border border-white/10 bg-white/10 sm:grid-cols-3">
              <div className="bg-[#0f1721] p-6 sm:p-7">
                <LockKeyhole className="h-5 w-5 text-[#f4b85a]" />
                <h3 className="mt-8 font-semibold">{t(copy.localTitle)}</h3>
                <p className="mt-3 text-sm leading-6 text-[#8f9bad]">{t(copy.localBody)}</p>
              </div>
              <div className="bg-[#0f1721] p-6 sm:p-7">
                <Network className="h-5 w-5 text-[#46a9d7]" />
                <h3 className="mt-8 font-semibold">{t(copy.evidenceTitle)}</h3>
                <p className="mt-3 text-sm leading-6 text-[#8f9bad]">{t(copy.evidenceBody)}</p>
              </div>
              <div className="bg-[#0f1721] p-6 sm:p-7">
                <Cpu className="h-5 w-5 text-[#8872ff]" />
                <h3 className="mt-8 font-semibold">{t(copy.universalTitle)}</h3>
                <p className="mt-3 text-sm leading-6 text-[#8f9bad]">{t(copy.universalBody)}</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="px-5 py-24 sm:px-8 lg:px-12 lg:py-32">
        <div className="mx-auto max-w-7xl">
          <div className="flex flex-col gap-6 border-b border-white/10 pb-10 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="eyebrow">{t(copy.releaseEyebrow)}</p>
              <h2 className="mt-4 text-4xl font-semibold tracking-[-0.055em]">{t(copy.releaseTitle)}</h2>
            </div>
            <a
              href="https://github.com/r3d42-git/MenuBarIO/releases"
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-2 text-sm font-medium text-[#bec7d4] hover:text-white"
            >
              {t(copy.allReleases)} <ArrowUpRight className="h-4 w-4" />
            </a>
          </div>
          <ol className="mt-10 grid grid-cols-2 gap-2 sm:grid-cols-5 lg:grid-cols-10" aria-label={t(copy.publishedVersions)}>
            {releases.map(([version, date], index) => (
              <li key={version} className="release-cell relative rounded-2xl border border-white/10 bg-[#0f1721] p-4">
                <span className="font-mono text-[9px] text-[#667386]">{String(index + 1).padStart(2, '0')}</span>
                <p className="mt-5 text-sm font-semibold">v{version}</p>
                <p className="mt-1 font-mono text-[9px] text-[#728095]">{date}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="px-5 pb-8 sm:px-8 lg:px-12">
        <div className="final-card relative mx-auto max-w-7xl overflow-hidden rounded-[32px] border border-white/10 p-8 sm:p-12 lg:p-16">
          <div className="absolute -right-20 -top-20 h-80 w-80 rounded-full bg-[#8872ff]/15 blur-[100px]" aria-hidden="true" />
          <div className="relative grid gap-12 lg:grid-cols-[1fr_auto] lg:items-center">
            <div className="max-w-3xl">
              <p className="eyebrow">{t(copy.finalEyebrow)}</p>
              <h2 className="mt-5 text-balance text-4xl font-semibold tracking-[-0.06em] sm:text-6xl">{t(copy.finalTitle)}</h2>
              <p className="mt-6 max-w-2xl text-base leading-8 text-[#aeb8c7]">{t(copy.finalBody)}</p>
              <div className="mt-9 flex flex-wrap gap-3">
                <a
                  href="https://github.com/r3d42-git/MenuBarIO"
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex h-11 items-center gap-2 rounded-full bg-white px-5 text-sm font-semibold text-[#10141c] hover:bg-[#e7ebf1]"
                >
                  <FolderGit className="h-4 w-4" /> {t(copy.openRepository)}
                </a>
                <a
                  href="https://github.com/r3d42-git/MenuBarIO/releases/tag/v0.5.0"
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex h-11 items-center gap-2 rounded-full border border-white/15 bg-white/[0.04] px-5 text-sm font-medium text-white hover:bg-white/[0.08]"
                >
                  {t(copy.releaseLabel)} <ArrowUpRight className="h-4 w-4" />
                </a>
              </div>
            </div>
            <img
              src={assetUrl('menubario-icon.png')}
              alt="MenuBarIO App Icon"
              className="h-36 w-36 rounded-[34px] shadow-[0_30px_80px_rgba(0,0,0,.42)] sm:h-44 sm:w-44 sm:rounded-[40px]"
            />
          </div>
        </div>
      </section>

      <footer className="px-5 py-10 text-xs text-[#687589] sm:px-8 lg:px-12">
        <div className="mx-auto flex max-w-7xl flex-col gap-4 border-t border-white/10 pt-7 sm:flex-row sm:items-center sm:justify-between">
          <p>{t(copy.footer)}</p>
          <a href="#top" className="inline-flex items-center gap-2 text-[#9ca9ba] hover:text-white">
            {t(copy.backToTop)} <ArrowDown className="h-3.5 w-3.5 rotate-180" />
          </a>
        </div>
      </footer>
    </main>
  );
}
