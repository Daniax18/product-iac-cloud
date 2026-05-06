import { Injectable } from '@angular/core';
import axios, { AxiosError } from 'axios';
import { LoginPayload, LoginResponse, Product, ProductPayload, RegisterPayload } from '../models/api.models';

const apiClient = axios.create({
  baseURL: '',
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.request.use((config) => {
  const requestUrl = config.url ?? '';
  const isPublicRoute =
    requestUrl.includes('/api/user/login') || requestUrl.includes('/api/user/register');

  if (!isPublicRoute) {
    const token = localStorage.getItem('auth_token');

    if (token) {
      config.headers.set('Authorization', `Bearer ${token}`);
    }
  }

  return config;
});

@Injectable({
  providedIn: 'root',
})
export class ApiService {
  async login(payload: LoginPayload): Promise<LoginResponse> {
    const { data } = await apiClient.post<LoginResponse>('/api/user/login', payload);
    localStorage.setItem('auth_token', data.token);
    localStorage.setItem('auth_user', JSON.stringify(data));
    return data;
  }

  async register(payload: RegisterPayload): Promise<unknown> {
    const { data } = await apiClient.post('/api/user/register', payload);
    return data;
  }

  async getProducts(): Promise<Product[]> {
    const { data } = await apiClient.get<Product[]>('/api/product');
    return data;
  }

  async createProduct(payload: ProductPayload): Promise<Product> {
    const { data } = await apiClient.post<Product>('/api/product', payload);
    return data;
  }

  getStoredUser(): LoginResponse | null {
    const user = localStorage.getItem('auth_user');
    return user ? (JSON.parse(user) as LoginResponse) : null;
  }

  logout(): void {
    localStorage.removeItem('auth_token');
    localStorage.removeItem('auth_user');
  }

  getErrorMessage(error: unknown): string {
    if (error instanceof AxiosError) {
      const apiMessage = error.response?.data;
      if (typeof apiMessage === 'string') {
        return apiMessage;
      }
      if (apiMessage && typeof apiMessage === 'object') {
        return 'La requete a echoue. Verifiez les donnees envoyees.';
      }
      if (error.response?.status === 401) {
        return 'Session invalide ou expiree. Reconnectez-vous.';
      }

      return error.message;
    }

    return 'Une erreur inattendue est survenue.';
  }
}
