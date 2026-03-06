import { CanActivateFn } from '@angular/router';

export const adminGuard: CanActivateFn = () => {
  const token = localStorage.getItem('token');
  if (!token) {
    console.warn('ADMIN GUARD: no token');
    return false;
  }

  const payload = JSON.parse(atob(token.split('.')[1]));

  const role =
    payload['role'] ||
    payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

  console.log('ADMIN GUARD ROLE:', role);

  return role === 'Admin';
};