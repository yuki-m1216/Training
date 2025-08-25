import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import Home from "../page";
import { act } from "react";

// Mock environment variables
const originalEnv = process.env;
beforeAll(() => {
  process.env = {
    ...originalEnv,
    NEXT_PUBLIC_API_URL: "http://localhost:3001",
  };
});

afterAll(() => {
  process.env = originalEnv;
});

//Mock fetch
const mockFetch = jest.fn() as jest.MockedFunction<typeof fetch>;
global.fetch = mockFetch;

describe("Home Component", () => {
  const mockUsers = [
    { id: 1, name: "John Doe", email: "john@example.com" },
    { id: 2, name: "Jane Smith", email: "jane@example.com" },
  ];
  beforeEach(() => {
    mockFetch.mockClear();
    mockFetch.mockResolvedValue({
      ok: true,
      json: async () => mockUsers,
    } as Response);
  });

  test("renders page title", () => {
    render(<Home />);
    expect(screen.getByText("User Management")).toBeInTheDocument();
  });

  test("display loading state initially", () => {
    render(<Home />);
    expect(screen.getByText("Loading users...")).toBeInTheDocument();
  });

  test("fetches and displays users on mount", async () => {
    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText("John Doe")).toBeInTheDocument();
      expect(screen.getByText("john@example.com")).toBeInTheDocument();
      expect(screen.getByText("Jane Smith")).toBeInTheDocument();
      expect(screen.getByText("jane@example.com")).toBeInTheDocument();
    });

    expect(mockFetch).toHaveBeenCalledWith("http://localhost:3001/users");
    expect(mockFetch).toHaveBeenCalledTimes(1);
  });

  test("displays error when fetch fails", async () => {
    mockFetch.mockRejectedValue(new Error("Network error"));

    await act(async () => {
      render(<Home />);
    });

    await waitFor(() => {
      expect(screen.getByText("Error: Network error")).toBeInTheDocument();
    });
  });

  test("render button refetches users", async () => {
    await act(async () => {
      render(<Home />);
    });

    // Wait for initial load
    await waitFor(() => {
      expect(screen.getByText("John Doe")).toBeInTheDocument();
    });

    // Click refresh button
    await act(async () => {
      const refreshButton = screen.getByText("Refresh Users");
      fireEvent.click(refreshButton);
    });

    expect(mockFetch).toHaveBeenCalledTimes(2);
  });
});
