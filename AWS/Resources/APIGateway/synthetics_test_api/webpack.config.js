const path = require("path");
module.exports = {
  entry: {
    index: "./lambda/src",
  },
  output: {
    path: path.join(__dirname, "lambda/dist"),
    filename: "[name].js", // [name]はentryで記述した名前(この例ではbundle）が入る
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
