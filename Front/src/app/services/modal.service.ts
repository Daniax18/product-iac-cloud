import { Injectable } from '@angular/core';
import { signal } from '@angular/core';

export interface ModalState {
  isOpen: boolean;
  title: string;
  content: string;
}

@Injectable({
  providedIn: 'root',
})
export class ModalService {
  private readonly modalState = signal<ModalState>({
    isOpen: false,
    title: '',
    content: '',
  });

  modalState$ = this.modalState.asReadonly();

  openModal(title: string, content: string): void {
    this.modalState.set({
      isOpen: true,
      title,
      content,
    });
  }

  closeModal(): void {
    this.modalState.set({
      isOpen: false,
      title: '',
      content: '',
    });
  }
}
