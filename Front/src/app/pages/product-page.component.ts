import { Component, inject, signal } from '@angular/core';
import { CommonModule, CurrencyPipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { ApiService } from '../services/api.service';
import { ModalService } from '../services/modal.service';
import { Product } from '../models/api.models';
import { environment } from '../../environments/environment';

@Component({
  selector: 'app-product-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink, CurrencyPipe],
  templateUrl: './product-page.component.html',
  styleUrl: './product-page.component.css',
})
export class ProductPageComponent {
  private readonly fb = inject(FormBuilder);
  private readonly api = inject(ApiService);
  private readonly router = inject(Router);
  private readonly modalService = inject(ModalService);

  protected readonly isLoading = signal(true);
  protected readonly isSubmitting = signal(false);
  protected readonly errorMessage = signal('');
  protected readonly successMessage = signal('');
  protected readonly products = signal<Product[]>([]);
  protected readonly currentUser = signal(this.api.getStoredUser());

  protected readonly form = this.fb.nonNullable.group({
    name: ['', Validators.required],
    price: [0, [Validators.required, Validators.min(0.01)]],
  });

  constructor() {
    void this.loadProducts();
  }

  protected async loadProducts(): Promise<void> {
    this.isLoading.set(true);
    this.errorMessage.set('');

    try {
      const products = await this.api.getProducts();
      this.products.set(products);
    } catch (error) {
      this.errorMessage.set(this.api.getErrorMessage(error));
    } finally {
      this.isLoading.set(false);
    }
  }

  protected async submit(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.isSubmitting.set(true);
    this.errorMessage.set('');
    this.successMessage.set('');

    try {
      const created = await this.api.createProduct(this.form.getRawValue());
      this.products.update((items) => [created, ...items]);
      this.successMessage.set('Produit cree avec succes.');
      this.form.reset({ name: '', price: 0 });
    } catch (error) {
      this.errorMessage.set(this.api.getErrorMessage(error));
    } finally {
      this.isSubmitting.set(false);
    }
  }

  protected logout(): void {
    this.api.logout();
    void this.router.navigate(['/login']);
  }

  protected openLicenceModal(): void {
    const year = new Date().getFullYear();
    const licenceContent = `Logiciel licencie a ${environment.clientName}

Siege social : ${environment.clientSiege}
Version 1.0.0

(c) ${year} - Tous droits reserves`;
    
    this.modalService.openModal('Licence client', licenceContent);
  }
}
