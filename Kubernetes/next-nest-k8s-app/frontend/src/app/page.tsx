'use client';

import React, { useState, useEffect, useCallback } from 'react';

/**
 * Next.js App Routerでのクライアントコンポーネント
 * 
 * 重要な技術的決定:
 * 1. SSR/SSGを無効化してクライアントサイドレンダリングのみ使用
 *    - 理由: Kubernetes環境でのハイドレーション問題を回避
 * 2. APIエンドポイントは環境変数ではなく相対パス'/api'を使用
 *    - 理由: ビルド時と実行時の環境差異を解消
 * 3. isClientフラグでクライアントサイドのみでレンダリング
 *    - 理由: サーバーサイドとクライアントサイドの不整合を防止
 */
export const dynamic = 'force-dynamic';

interface User {
  id: number;
  name: string;
  email: string;
}

export default function Home() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newUser, setNewUser] = useState({ name: '', email: '' });
  const [creating, setCreating] = useState(false);
  const [isClient, setIsClient] = useState(false);

  // APIエンドポイント: Ingressで/apiパスをバックエンドにプロキシ
  // Docker Compose環境では直接ポート3001を使用
  // Kubernetes環境ではIngressが/apiを適切にルーティング
  const apiUrl = '/api';

  const fetchUsers = useCallback(async () => {
    if (!isClient) return;
    
    console.log('fetchUsers called, apiUrl:', apiUrl);
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${apiUrl}/users`);
      console.log('Response status:', response.status, 'ok:', response.ok);

      if (!response.ok) {
        throw new Error(`Failed to fetch users: ${response.status}`);
      }

      const data = await response.json();
      console.log('Fetched data:', data);
      setUsers(data);
    } catch (err) {
      console.error('fetchUsers error:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, [apiUrl, isClient]);

  const createUser = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();
      if (!newUser.name.trim() || !newUser.email.trim()) {
        setError('Name and email are required');
        return;
      }

      setCreating(true);
      setError(null);

      try {
        const response = await fetch(`${apiUrl}/users`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(newUser),
        });

        if (!response.ok) {
          throw new Error('Failed to create user');
        }

        const createdUser = await response.json();
        setUsers((prev) => [...prev, createdUser]);
        setNewUser({ name: '', email: '' });
        setShowCreateForm(false);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setCreating(false);
      }
    },
    [apiUrl, newUser]
  );

  const deleteUser = useCallback(
    async (userId: number) => {
      if (!confirm('Are you sure you want to delete this user?')) {
        return;
      }

      setError(null);

      try {
        const response = await fetch(`${apiUrl}/users/${userId}`, {
          method: 'DELETE',
        });

        if (!response.ok) {
          throw new Error('Failed to delete user');
        }

        setUsers((prev) => prev.filter((user) => user.id !== userId));
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      }
    },
    [apiUrl]
  );

  // クライアントサイドハイドレーション用のフラグ設定
  // サーバーサイドでは false、クライアントサイドで true になる
  useEffect(() => {
    setIsClient(true);
  }, []);

  // クライアントサイドでのみユーザーデータを取得
  // これによりSSR時のAPIコール失敗を防ぐ
  useEffect(() => {
    if (isClient) {
      fetchUsers();
    }
  }, [isClient, fetchUsers]);

  // サーバーサイドレンダリング時は簡易版を表示
  // ハイドレーションミスマッチを防ぐため
  if (!isClient) {
    return (
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">User Management</h1>
        <p>Loading...</p>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">User Management</h1>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          Error: {error}
        </div>
      )}

      <div className="mb-6 flex gap-4">
        <button
          onClick={fetchUsers}
          disabled={loading}
          className="py-2 px-4 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
        >
          {loading ? 'Loading...' : 'Refresh Users'}
        </button>

        <button
          onClick={() => setShowCreateForm(!showCreateForm)}
          className="py-2 px-4 bg-green-500 text-white rounded hover:bg-green-600"
        >
          {showCreateForm ? 'Cancel' : 'Add New User'}
        </button>
      </div>

      {showCreateForm && (
        <div className="bg-gray-100 p-6 rounded mb-6">
          <h2 className="text-xl font-semibold mb-4">Create New User</h2>
          <form onSubmit={createUser} className="space-y-4">
            <div>
              <label
                htmlFor="name"
                className="block text-sm font-medium text-gray-700"
              >
                Name
              </label>
              <input
                type="text"
                id="name"
                value={newUser.name}
                onChange={(e) =>
                  setNewUser((prev) => ({ ...prev, name: e.target.value }))
                }
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>
            <div>
              <label
                htmlFor="email"
                className="block text-sm font-medium text-gray-700"
              >
                Email
              </label>
              <input
                type="email"
                id="email"
                value={newUser.email}
                onChange={(e) =>
                  setNewUser((prev) => ({ ...prev, email: e.target.value }))
                }
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                required
              />
            </div>
            <div className="flex gap-2">
              <button
                type="submit"
                disabled={creating}
                className="py-2 px-4 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
              >
                {creating ? 'Creating...' : 'Create User'}
              </button>
              <button
                type="button"
                onClick={() => setShowCreateForm(false)}
                className="py-2 px-4 bg-gray-300 text-gray-700 rounded hover:bg-gray-400"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="mb-4 p-4 bg-yellow-100 rounded">
        <p><strong>Debug Info:</strong></p>
        <p>Users count: {users.length}</p>
        <p>Loading: {loading.toString()}</p>
        <p>Client-side: {isClient.toString()}</p>
        <p>Error: {error || 'none'}</p>
        <p>API URL: {apiUrl}</p>
      </div>

      <div className="grid gap-4">
        {users.map((user) => (
          <div
            key={user.id}
            className="border p-4 rounded shadow flex justify-between items-center"
          >
            <div>
              <h2 className="text-xl font-semibold">{user.name}</h2>
              <p className="text-gray-600">{user.email}</p>
            </div>
            <button
              onClick={() => deleteUser(user.id)}
              className="py-1 px-3 bg-red-500 text-white rounded hover:bg-red-600 text-sm"
            >
              Delete
            </button>
          </div>
        ))}
      </div>
      {users.length === 0 && !loading && (
        <p className="text-center text-gray-500 py-8">No users found.</p>
      )}
    </div>
  );
}
