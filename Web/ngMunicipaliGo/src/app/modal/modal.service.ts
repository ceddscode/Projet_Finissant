import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export type ModalType = 'success' | 'danger' | 'info';
export type ModalKind = 'simple' | 'refuse';

@Injectable({ providedIn: 'root' })
export class ModalService {
  open$ = new BehaviorSubject(false);
  title$ = new BehaviorSubject<string>('');
  type$ = new BehaviorSubject<ModalType>('info');
  kind$ = new BehaviorSubject<ModalKind>('simple');
  descPlaceholder$ = new BehaviorSubject<string>('');

  private onClose?: (result?: any) => void;

  open(options: {
    title: string;
    type?: ModalType;
    kind?: ModalKind;
    descPlaceholder?: string;
    onClose?: (result?: any) => void;
  }) {
    this.title$.next(options.title);
    this.type$.next(options.type ?? 'info');
    this.kind$.next(options.kind ?? 'simple');
    this.descPlaceholder$.next(options.descPlaceholder ?? '');

    this.open$.next(true);
    this.onClose = options.onClose;

    document.body.style.overflow = 'hidden';
  }

  close(result?: any) {
    this.open$.next(false);
    document.body.style.overflow = 'auto';

    this.onClose?.(result);
    this.onClose = undefined;
  }
}
