import { API_BASE } from './apiBase';

export async function updateProfile(
    token: string,
    data: { name?: string; bio?: string; emergencyContacts?: any[] }
) {
    const res = await fetch(`${API_BASE}/users/update-profile`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(data),
    });
    const json = await res.json();
    if (!res.ok) throw json;
    return json;
}

export async function updateAvatar(token: string, formData: FormData) {
    const res = await fetch(`${API_BASE}/users/update-avatar`, {
        method: 'PUT',
        headers: {
            Authorization: `Bearer ${token}`,
        },
        body: formData,
    });
    const json = await res.json();
    if (!res.ok) throw json;
    return json;
}
