import React from "react";

const Homepage = () => {
  return (
    <div>
      <div className="w-screen mt-10">
        <div className="w-11/12 mx-auto">
            <div className="flex md:flex-row flex-col">
                <div className="md:w-3/5 w-full">
                    <div className="w-full flex-col md:h-screen">
                        <div className="px-10 py-2 md:h-1/2 bg-yellow-500 rounded-2xl">
                          <div>
                            <p className="text-black">hello</p>
                          </div>
                        </div>
                        <div className="flex md:h-1/2 md:flex-row flex-col mt-3 w-full">
                            <div className="px-10 py-2 md:mr-2 bg-white md:mt-0 mt-3 md:w-1/2 w-full rounded-2xl"></div>
                            <div className="px-10 py-2 md:ml-2 bg-white md:mt-0 mt-3 md:w-1/2 w-full rounded-2xl"></div>
                        </div>
                    </div>
                </div>
                <div className="md:w-2/5 w-full">
                    <div className="w-full md:h-screen">
                        <div className="px-10 py-2 md:mr-2 border-4 border-white md:mx-5 mx-0 mt-5 md:mt-0 rounded-2xl md:h-full"></div>
                    </div>
                </div>
            </div>
        </div>
      </div>
    </div>
  );
};

export default Homepage;
