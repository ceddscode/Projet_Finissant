import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { ModalService } from '../modal/modal.service';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = localStorage.getItem('token');
  const router = inject(Router);
  const modal = inject(ModalService);

  const clonedRequest = req.clone({
    setHeaders: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      'X-Client-Type': 'web'
    }
  });

  return next(clonedRequest).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        localStorage.removeItem('token');
        modal.open({
          title: 'modal.sessionExpired',
          type: 'danger',
          kind: 'simple',
          onClose: () => router.navigate(['/login'])
        });
      }
      return throwError(() => error);
    })
  );
};