import Head from "next/head";
import type { AppProps } from "next/app";
import { ToastContainer } from "react-toastify";
import { WagmiProvider } from 'wagmi';
import {
  getDefaultConfig,
  RainbowKitProvider,
} from '@rainbow-me/rainbowkit';
import {
  QueryClientProvider,
  QueryClient,
} from "@tanstack/react-query";
import { sepolia } from 'wagmi/chains';

import "../styles/globals.css";
import '@rainbow-me/rainbowkit/styles.css';
import "react-toastify/dist/ReactToastify.css";

const config = getDefaultConfig({
  appName: 'CrowdFunding',
  projectId: process.env.NEXT_PUBLIC_RAINBOW_PROJECT_ID || '',
  chains: [sepolia],
  ssr: false, // If your dApp uses server side rendering (SSR)
});

function MyApp({ Component, pageProps }: AppProps) {
  const AnyComponent = Component as any;
  const queryClient = new QueryClient();

  return (
    <>
      <Head>
        <meta charSet="utf-8" />
        <meta httpEquiv="X-UA-Compatible" content="IE=edge" />
        <meta
          name="viewport"
          content="width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=1,user-scalable=no"
        />
        <meta name="description" content="Simple token scan frontend" />

        <title>Simple CrowdFunding UI</title>
        <link rel="icon" href="/favicon.ico"></link>
        <link rel="manifest" href="/manifest.json" />
        <link rel="shortcut icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" href="/apple-icon.png"></link>
      </Head>
      <ToastContainer
        position="top-right"
        closeOnClick
        hideProgressBar={false}
      />
      <WagmiProvider config={config}>
        <QueryClientProvider client={queryClient}>
          <RainbowKitProvider>
            <AnyComponent {...pageProps} />
          </RainbowKitProvider>
        </QueryClientProvider>
      </WagmiProvider>
    </>
  );
}

export default MyApp;
