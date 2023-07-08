import "../styles/globals.css";
import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultWallets, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { configureChains, createConfig, WagmiConfig } from "wagmi";
import { polygonMumbai } from "wagmi/chains";
import { alchemyProvider } from "wagmi/providers/alchemy";
import { publicProvider } from "wagmi/providers/public";
import localFont from "next/font/local";
import Navbar from "../components/navbar";
import { R3vlProvider, createClient as r3vlCreateClient } from "@r3vl/sdk";

const r3vlClient = r3vlCreateClient();

const { chains, publicClient } = configureChains(
  [polygonMumbai],
  [
    alchemyProvider({ apiKey: process.env.NEXT_PUBLIC_ALCHEMY_ID }),
    publicProvider(),
  ]
);

const { connectors } = getDefaultWallets({
  appName: "My RainbowKit App",
  projectId: "YOUR_PROJECT_ID",
  chains,
});

const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
});
const myFont = localFont({ src: "./CalSans-SemiBold.woff2" });

function MyApp({ Component, pageProps }) {
  return (
    <WagmiConfig config={wagmiConfig}>
      <RainbowKitProvider chains={chains}>
        <R3vlProvider client={r3vlClient}>
          <main className={myFont.className}>
            <Navbar />
            <Component {...pageProps} />
          </main>
        </R3vlProvider>
      </RainbowKitProvider>
    </WagmiConfig>
  );
}

export default MyApp;
