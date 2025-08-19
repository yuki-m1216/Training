const path = require("path");
module.exports = {
  entry: {
    index: "./lambda/src",
  },
  output: {
    path: path.join(__dirname, "lambda/dist"),
    filename: "index.js",
    libraryTarget: 'commonjs2',
  },
  resolve: {
    extensions: [".ts", ".js"],
  },
  devServer: {
    static: {
      directory: path.join(__dirname, "dist"),
    },
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        loader: "ts-loader",
      },
    ],
  },
};
