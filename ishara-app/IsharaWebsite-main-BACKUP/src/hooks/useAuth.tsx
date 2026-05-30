import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { getMe } from '../api/authApi';

interface User {
    id: string;
    email: string;
    name: string;
    role: string;
    isVerified: boolean;
    profilePic?: string;
    bio?: string;
    disabilityType?: string;
    emergencyContacts?: { _id?: string; name: string; phone: string; email: string; relationship: string }[];
}

interface AuthContextType {
    user: User | null;
    token: string | null;
    isAuthenticated: boolean;
    isLoading: boolean;
    login: (token: string, user: User) => void;
    logout: () => void;
    refreshUser: () => Promise<void>;
    updateUser: (partial: Partial<User>) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
    const [user, setUser] = useState<User | null>(null);
    const [token, setToken] = useState<string | null>(() => localStorage.getItem('token'));
    const [isLoading, setIsLoading] = useState(!!localStorage.getItem('token'));

    useEffect(() => {
        if (token) {
            refreshUser();
        }
    }, []);

    const refreshUser = async () => {
        if (!token) return;
        setIsLoading(true);
        try {
            const data = await getMe(token);
            setUser(data.user);
        } catch {
            // Token expired or invalid
            handleLogout();
        } finally {
            setIsLoading(false);
        }
    };

    const handleLogin = (newToken: string, userData: User) => {
        localStorage.setItem('token', newToken);
        setToken(newToken);
        setUser(userData);
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        setToken(null);
        setUser(null);
    };

    const handleUpdateUser = (partial: Partial<User>) => {
        setUser(prev => prev ? { ...prev, ...partial } : prev);
    };

    return (
        <AuthContext.Provider
            value={{
                user,
                token,
                isAuthenticated: !!user,
                isLoading,
                login: handleLogin,
                logout: handleLogout,
                refreshUser,
                updateUser: handleUpdateUser,
            }}
        >
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const ctx = useContext(AuthContext);
    if (!ctx) throw new Error('useAuth must be used within AuthProvider');
    return ctx;
}
