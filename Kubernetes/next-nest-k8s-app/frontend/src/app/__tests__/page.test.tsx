import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import Home from '../page';
import { act } from 'react';

// Mock environment variables
const originalEnv = process.env;
beforeAll(() => {
  process.env = {
    ...originalEnv,
    NEXT_PUBLIC_API_URL: 'http://localhost:3001',
  };
});

afterAll(() => {
  process.env = originalEnv;
});

//Mock fetch
const mockFetch = jest.fn() as jest.MockedFunction<typeof fetch>;
global.fetch = mockFetch;

describe('Home Component', () => {
  const mockUsers = [
    { id: 1, name: 'John Doe', email: 'john@example.com' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com' },
  ];
  beforeEach(() => {
    mockFetch.mockClear();
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => mockUsers,
    } as Response);
  });

  test('renders page title', () => {
    render(<Home />);
    expect(screen.getByText('User Management')).toBeInTheDocument();
  });

  test('display loading state initially', () => {
    render(<Home />);
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  test('fetches and displays users on mount', async () => {
    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('john@example.com')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
      expect(screen.getByText('jane@example.com')).toBeInTheDocument();
    });

    expect(mockFetch).toHaveBeenCalledWith('http://localhost:3001/users');
    expect(mockFetch).toHaveBeenCalledTimes(1);
  });

  test('displays error when fetch fails', async () => {
    mockFetch.mockRejectedValue(new Error('Network error'));

    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText('Error: Network error')).toBeInTheDocument();
    });
  });

  test('render button refetches users', async () => {
    await act(async () => {
      render(<Home />);
    });

    // Wait for initial load
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    // Click refresh button
    await act(async () => {
      const refreshButton = screen.getByText('Refresh Users');
      fireEvent.click(refreshButton);
    });

    expect(mockFetch).toHaveBeenCalledTimes(2);
  });

  test('shows create form when Add New User button is clicked', async () => {
    await act(async () => {
      render(<Home />);
    });

    // Wait for initial load
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    // Click Add New User button
    await act(async () => {
      const addButton = screen.getByText('Add New User');
      fireEvent.click(addButton);
    });

    // Check if form is displayed
    expect(screen.getByText('Create New User')).toBeInTheDocument();
    expect(screen.getByLabelText('Name')).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: 'Create User' })
    ).toBeInTheDocument();
  });

  test('hides create form when Cancel button is clicked', async () => {
    await act(async () => {
      render(<Home />);
    });

    // Wait for initial load and show form
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    await act(async () => {
      const addButton = screen.getByText('Add New User');
      fireEvent.click(addButton);
    });

    expect(screen.getByText('Create New User')).toBeInTheDocument();

    // Click Cancel button in the form
    await act(async () => {
      const cancelButtons = screen.getAllByRole('button', { name: 'Cancel' });
      fireEvent.click(cancelButtons[1]); // Select the form cancel button
    });

    // Form should be hidden
    expect(screen.queryByText('Create New User')).not.toBeInTheDocument();
  });

  test('creates new user successfully', async () => {
    const newUser = { id: 3, name: 'New User', email: 'newuser@example.com' };

    // Mock successful POST request
    mockFetch.mockImplementation((_, options) => {
      if (options && options.method === 'POST') {
        return Promise.resolve({
          ok: true,
          json: async () => newUser,
        } as Response);
      }
      return Promise.resolve({
        ok: true,
        json: async () => mockUsers,
      } as Response);
    });

    await act(async () => {
      render(<Home />);
    });

    // Wait for initial load and show form
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    await act(async () => {
      const addButton = screen.getByText('Add New User');
      fireEvent.click(addButton);
    });

    // Fill in form
    await act(async () => {
      const nameInput = screen.getByLabelText('Name');
      const emailInput = screen.getByLabelText('Email');

      fireEvent.change(nameInput, { target: { value: 'New User' } });
      fireEvent.change(emailInput, {
        target: { value: 'newuser@example.com' },
      });
    });

    // Submit form
    await act(async () => {
      const createButton = screen.getByRole('button', { name: 'Create User' });
      fireEvent.click(createButton);
    });

    // Check if POST request was made
    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('http://localhost:3001/users', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: 'New User',
          email: 'newuser@example.com',
        }),
      });
    });

    // Check if new user appears in the list
    await waitFor(() => {
      expect(screen.getByText('New User')).toBeInTheDocument();
      expect(screen.getByText('newuser@example.com')).toBeInTheDocument();
    });

    // Form should be hidden after successful creation
    expect(screen.queryByText('Create New User')).not.toBeInTheDocument();
  });

  test('shows error message when user creation fails', async () => {
    // Mock failed POST request
    mockFetch.mockImplementation((_, options) => {
      if (options && options.method === 'POST') {
        return Promise.resolve({
          ok: false,
          status: 400,
        } as Response);
      }
      return Promise.resolve({
        ok: true,
        json: async () => mockUsers,
      } as Response);
    });

    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    await act(async () => {
      const addButton = screen.getByText('Add New User');
      fireEvent.click(addButton);
    });

    // Fill and submit form
    await act(async () => {
      const nameInput = screen.getByLabelText('Name');
      const emailInput = screen.getByLabelText('Email');

      fireEvent.change(nameInput, { target: { value: 'Test User' } });
      fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    });

    await act(async () => {
      const createButton = screen.getByRole('button', { name: 'Create User' });
      fireEvent.click(createButton);
    });

    // Check if error message is displayed
    await waitFor(() => {
      expect(
        screen.getByText('Error: Failed to create user')
      ).toBeInTheDocument();
    });
  });

  test('validates required fields', async () => {
    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    await act(async () => {
      const addButton = screen.getByText('Add New User');
      fireEvent.click(addButton);
    });

    // Fill in only whitespace to test trim functionality
    await act(async () => {
      const nameInput = screen.getByLabelText('Name');
      const emailInput = screen.getByLabelText('Email');

      // Remove required attribute to test JS validation
      nameInput.removeAttribute('required');
      emailInput.removeAttribute('required');

      // Set whitespace values
      fireEvent.change(nameInput, { target: { value: '   ' } });
      fireEvent.change(emailInput, { target: { value: '   ' } });
    });

    // Try to submit form with whitespace
    await act(async () => {
      const createButton = screen.getByRole('button', { name: 'Create User' });
      fireEvent.click(createButton);
    });

    // Check if validation error is displayed
    await waitFor(() => {
      expect(
        screen.getByText('Error: Name and email are required')
      ).toBeInTheDocument();
    });

    // No POST request should be made
    expect(mockFetch).toHaveBeenCalledTimes(1); // Only the initial GET request
  });

  test('deletes user successfully', async () => {
    // Mock successful DELETE request
    mockFetch.mockImplementation((_, options) => {
      if (options && options.method === 'DELETE') {
        return Promise.resolve({
          ok: true,
        } as Response);
      }
      return Promise.resolve({
        ok: true,
        json: async () => mockUsers,
      } as Response);
    });

    // Mock window.confirm
    const mockConfirm = jest.spyOn(window, 'confirm');
    mockConfirm.mockImplementation(() => true);

    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    // Click delete button for first user
    await act(async () => {
      const deleteButtons = screen.getAllByText('Delete');
      fireEvent.click(deleteButtons[0]);
    });

    // Check if DELETE request was made
    await waitFor(() => {
      expect(mockFetch).toHaveBeenCalledWith('http://localhost:3001/users/1', {
        method: 'DELETE',
      });
    });

    // Check if user is removed from the list
    await waitFor(() => {
      expect(screen.queryByText('John Doe')).not.toBeInTheDocument();
    });

    mockConfirm.mockRestore();
  });

  test('cancels user deletion when user clicks cancel in confirmation dialog', async () => {
    // Mock window.confirm to return false
    const mockConfirm = jest.spyOn(window, 'confirm');
    mockConfirm.mockImplementation(() => false);

    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    // Click delete button
    await act(async () => {
      const deleteButtons = screen.getAllByText('Delete');
      fireEvent.click(deleteButtons[0]);
    });

    // No DELETE request should be made
    expect(mockFetch).toHaveBeenCalledTimes(1); // Only the initial GET request

    // User should still be in the list
    expect(screen.getByText('John Doe')).toBeInTheDocument();

    mockConfirm.mockRestore();
  });

  test('shows error message when user deletion fails', async () => {
    // Mock failed DELETE request
    mockFetch.mockImplementation((_, options) => {
      if (options && options.method === 'DELETE') {
        return Promise.resolve({
          ok: false,
          status: 500,
        } as Response);
      }
      return Promise.resolve({
        ok: true,
        json: async () => mockUsers,
      } as Response);
    });

    // Mock window.confirm
    const mockConfirm = jest.spyOn(window, 'confirm');
    mockConfirm.mockImplementation(() => true);

    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    // Click delete button
    await act(async () => {
      const deleteButtons = screen.getAllByText('Delete');
      fireEvent.click(deleteButtons[0]);
    });

    // Check if error message is displayed
    await waitFor(() => {
      expect(
        screen.getByText('Error: Failed to delete user')
      ).toBeInTheDocument();
    });

    // User should still be in the list
    expect(screen.getByText('John Doe')).toBeInTheDocument();

    mockConfirm.mockRestore();
  });
});
