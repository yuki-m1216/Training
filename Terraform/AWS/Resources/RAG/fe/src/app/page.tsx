"use client";

import { useState } from "react";
console.log(process.env.NEXT_PUBLIC_API_URL);
console.log(process.env.ENV);
export default function Home() {
  const [question, setQuestion] = useState("");
  const [answer, setAnswer] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!question.trim()) return;

    setLoading(true);
    setAnswer("");

    try {
      if (!process.env.NEXT_PUBLIC_API_URL) {
        throw new Error("API URL is not defined in the environment variables.");
      }

      const response = await fetch(
        process.env.NEXT_PUBLIC_API_URL + "resource",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          mode: "cors",
          body: JSON.stringify({ question }),
        }
      );

      const data = await response.json();
      setAnswer(data.answer || "回答が取得できませんでした。");
    } catch (error) {
      console.error("Error:", error);
      setAnswer("エラーが発生しました。");
    }

    setLoading(false);
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gray-100 p-4">
      <h1 className="text-2xl font-bold mb-4">AWS Bedrock FAQ 質問システム</h1>

      <form
        onSubmit={handleSubmit}
        className="w-full max-w-lg bg-white p-6 shadow-md rounded-lg"
      >
        <textarea
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          placeholder="質問を入力してください..."
          className="w-full p-2 border rounded-md"
          rows={4}
        />

        <button
          type="submit"
          className="mt-3 w-full bg-blue-500 text-white p-2 rounded-md hover:bg-blue-600"
          disabled={loading}
        >
          {loading ? "送信中..." : "質問する"}
        </button>
      </form>

      {answer && (
        <div className="mt-4 p-4 bg-white shadow-md rounded-lg max-w-lg">
          <h2 className="text-lg font-semibold">回答:</h2>
          <p className="mt-2">{answer}</p>
        </div>
      )}
    </main>
  );
}
