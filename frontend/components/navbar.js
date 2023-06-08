import { ConnectButton } from "@rainbow-me/rainbowkit";
import React from "react";

const Navbar = () => {
  return (
    <div>
      <div className="w-screen">
        <div className="flex flex-row justify-between mt-6 mx-10 align-middle">
          <div>
            <p className="text-4xl text-yellow-500">WASP.</p>
          </div>
          <div>
            <ConnectButton />
          </div>
        </div>
      </div>
    </div>
  );
};

export default Navbar;
