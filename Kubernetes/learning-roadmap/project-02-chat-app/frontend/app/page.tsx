  import Link from 'next/link';

  export default function Home() {
    return (
      <main className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-500 
  to-purple-600">
        <div className="text-center text-white">
          <h1 className="text-5xl font-bold mb-8">リアルタイムチャット</h1>
          <p className="text-xl mb-8">Socket.ioを使用したリアルタイムメッセージング</p>
          <Link
            href="/chat"
            className="inline-block px-8 py-3 bg-white text-blue-600 font-semibold rounded-lg 
  hover:bg-gray-100 transition-colors"
          >
            チャットを開始
          </Link>
        </div>
      </main>
    );
  }