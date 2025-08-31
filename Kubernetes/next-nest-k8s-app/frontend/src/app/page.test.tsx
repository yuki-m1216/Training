/**
 * テスト: フロントエンドページコンポーネント
 * 
 * API URLが/apiに変更されたことに対するテスト
 * - クライアントサイドレンダリングの確認
 * - APIエンドポイントの確認
 * - モック環境での動作確認
 */

import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import Home from './page';

// fetchのモック
global.fetch = jest.fn();

describe('Home Component', () => {
  beforeEach(() => {
    // fetchのモックをリセット
    (fetch as jest.Mock).mockClear();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('初期状態でLoading...が表示される', () => {
    // APIモックの設定（初期fetch用）
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      status: 200,
      json: async () => [],
    });

    render(<Home />);
    
    // クライアントサイドハイドレーション前はLoading...が表示
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  it('クライアントサイドマウント後にUser Managementが表示される', async () => {
    // APIモックの設定
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      status: 200,
      json: async () => [
        { id: 1, name: 'Test User', email: 'test@example.com' },
      ],
    });

    render(<Home />);

    // クライアントサイドハイドレーション後を待機
    await waitFor(() => {
      expect(screen.getByText('User Management')).toBeInTheDocument();
    });

    // API URLがデバッグ情報に表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('API URL: /api')).toBeInTheDocument();
    });
  });

  it('APIエンドポイントが正しく設定されている', async () => {
    // APIモックの設定
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      status: 200,
      json: async () => [],
    });

    render(<Home />);

    // クライアントサイドマウント後のAPI呼び出しを待機
    await waitFor(() => {
      expect(fetch).toHaveBeenCalledWith('/api/users');
    });
  });

  it('APIからユーザーデータを正しく取得・表示する', async () => {
    const mockUsers = [
      { id: 1, name: 'John Doe', email: 'john@example.com' },
      { id: 2, name: 'Jane Smith', email: 'jane@example.com' },
    ];

    // APIモックの設定
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      status: 200,
      json: async () => mockUsers,
    });

    render(<Home />);

    // ユーザーデータが表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
      expect(screen.getByText('john@example.com')).toBeInTheDocument();
      expect(screen.getByText('jane@example.com')).toBeInTheDocument();
    });

    // ユーザー数がデバッグ情報に表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('Users count: 2')).toBeInTheDocument();
    });
  });

  it('APIエラー時にエラーメッセージが表示される', async () => {
    // APIエラーのモック設定
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: false,
      status: 500,
    });

    render(<Home />);

    // エラーメッセージが表示されることを確認
    await waitFor(() => {
      const errorDiv = document.querySelector('.bg-red-100');
      expect(errorDiv).toBeInTheDocument();
      expect(errorDiv?.textContent).toContain('Error: Failed to fetch users: 500');
    });
  });

  it('Refresh Usersボタンが正しく動作する', async () => {
    // 初回API呼び出しのモック
    (fetch as jest.Mock)
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => [{ id: 1, name: 'Initial User', email: 'initial@example.com' }],
      })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => [{ id: 2, name: 'Refreshed User', email: 'refreshed@example.com' }],
      });

    render(<Home />);

    // 初期データの表示を待機
    await waitFor(() => {
      expect(screen.getByText('Initial User')).toBeInTheDocument();
    });

    // Refresh Usersボタンをクリック
    const refreshButton = screen.getByText('Refresh Users');
    fireEvent.click(refreshButton);

    // 更新されたデータが表示されることを確認
    await waitFor(() => {
      expect(screen.getByText('Refreshed User')).toBeInTheDocument();
    });

    // APIが2回呼ばれていることを確認
    expect(fetch).toHaveBeenCalledTimes(2);
    expect(fetch).toHaveBeenCalledWith('/api/users');
  });

  it('Add New Userボタンでフォームが表示される', async () => {
    // APIモックの設定
    (fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      status: 200,
      json: async () => [],
    });

    render(<Home />);

    // クライアントサイドマウント後を待機
    await waitFor(() => {
      expect(screen.getByText('User Management')).toBeInTheDocument();
    });

    // Add New Userボタンをクリック
    const addButton = screen.getByText('Add New User');
    fireEvent.click(addButton);

    // フォームが表示されることを確認
    expect(screen.getByText('Create New User')).toBeInTheDocument();
    expect(screen.getByLabelText('Name')).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
  });
});