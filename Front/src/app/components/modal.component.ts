import { Component, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ModalService } from '../services/modal.service';

@Component({
  selector: 'app-modal',
  standalone: true,
  imports: [CommonModule],
  template: `
    @if (isOpen()) {
      <div class="modal-overlay" (click)="close()">
        <div class="modal-content" (click)="$event.stopPropagation()">
          <div class="modal-header">
            <h2>{{ title() }}</h2>
            <button class="close-btn" (click)="close()" aria-label="Fermer">&times;</button>
          </div>

          <div class="modal-body">
            {{ content() }}
          </div>

          <div class="modal-footer">
            <button class="btn-primary" (click)="close()">Fermer</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.5);
      backdrop-filter: blur(5px);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      animation: fadeIn 0.3s ease-in-out;
    }

    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }

    .modal-content {
      background: linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0.05) 100%);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(255, 255, 255, 0.2);
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
      width: 90%;
      max-width: 500px;
      padding: 0;
      animation: slideIn 0.3s ease-in-out;
      color: #f5f5f5;
    }

    @keyframes slideIn {
      from {
        transform: translateY(-50px);
        opacity: 0;
      }
      to {
        transform: translateY(0);
        opacity: 1;
      }
    }

    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 24px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }

    .modal-header h2 {
      margin: 0;
      font-size: 1.5rem;
      color: #b85c38;
    }

    .close-btn {
      background: none;
      border: none;
      font-size: 28px;
      cursor: pointer;
      color: #f5f5f5;
      padding: 0;
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: color 0.2s;
    }

    .close-btn:hover {
      color: #b85c38;
    }

    .modal-body {
      padding: 24px;
      line-height: 1.6;
      max-height: 60vh;
      overflow-y: auto;
      white-space: pre-line;
    }

    .modal-footer {
      padding: 16px 24px;
      border-top: 1px solid rgba(255, 255, 255, 0.1);
      display: flex;
      justify-content: flex-end;
      gap: 12px;
    }

    .btn-primary {
      background: #b85c38;
      color: #f5f5f5;
      border: none;
      padding: 10px 24px;
      border-radius: 6px;
      cursor: pointer;
      font-size: 1rem;
      transition: background 0.2s;
    }

    .btn-primary:hover {
      background: #a0512d;
    }

    .modal-body::-webkit-scrollbar {
      width: 8px;
    }

    .modal-body::-webkit-scrollbar-track {
      background: rgba(255, 255, 255, 0.05);
    }

    .modal-body::-webkit-scrollbar-thumb {
      background: rgba(184, 92, 56, 0.5);
      border-radius: 4px;
    }

    .modal-body::-webkit-scrollbar-thumb:hover {
      background: #b85c38;
    }
  `]
})
export class ModalComponent {
  private readonly modalService = inject(ModalService);
  private readonly modalState = this.modalService.modalState$;

  isOpen = computed(() => this.modalState().isOpen);
  title = computed(() => this.modalState().title);
  content = computed(() => this.modalState().content);

  close(): void {
    this.modalService.closeModal();
  }
}