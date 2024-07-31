import { ConnectButton } from "@rainbow-me/rainbowkit";

export const PageHeader = () => (
  <header className="bg-white">
    <nav
      className="mx-auto flex max-w-7xl items-center justify-between p-4 lg:px-8"
      aria-label="Global"
    >
      <div className="flex flex-1">
        <a href="/" className="-m-1.5 p-1.5">
          <img className="h-8 w-auto" src="/logo.svg" alt="logo-svg" />
        </a>
      </div>
      <ConnectButton />
    </nav>
  </header>
);
