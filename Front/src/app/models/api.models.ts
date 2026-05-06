export interface LoginPayload {
  email: string;
  password: string;
}

export interface RegisterPayload {
  userName: string;
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  userId: string;
  userName: string;
  email: string;
}

export interface ProductPayload {
  name: string;
  price: number;
}

export interface Product {
  id?: number | string;
  name: string;
  price: number;
}
