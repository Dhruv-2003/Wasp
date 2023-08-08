import "../styles/globals.css";
// import { RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { R3vlProvider, createClient as r3vlCreateClient } from "@r3vl/sdk";
import { configureChains, createClient } from "wagmi";
import { mainnet, polygon, polygonMumbai } from "wagmi/chains";
import { publicProvider } from "wagmi/providers/public";
import { getDefaultWallets, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { WagmiConfig } from "wagmi";
import "@rainbow-me/rainbowkit/styles.css";

import localFont from "next/font/local";

const { chains, provider } = configureChains(
  [polygonMumbai],
  [publicProvider()]
);

const projectId = "84ac6c94812e6453ba180e053d640ea3";

const { wallets, connectors } = getDefaultWallets({
  appName: "My RainbowKit App",
  projectId,
  chains,
});

const wagmiClient = createClient({
  autoConnect: true,
  connectors,
  provider,
});

const r3vlClient = r3vlCreateClient();

const myFont = localFont({ src: "./CalSans-SemiBold.woff2" });

export default function App({ Component, pageProps }) {
  return (
    <R3vlProvider client={r3vlClient}>
      <WagmiConfig client={wagmiClient}>
        <RainbowKitProvider chains={chains}>
          <main className={myFont.className}>
            <Component {...pageProps} />
          </main>
        </RainbowKitProvider>
      </WagmiConfig>
    </R3vlProvider>
  );
}
