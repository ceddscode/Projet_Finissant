export function enumToOptions<T extends object>(enumObj: T) {
  return Object.entries(enumObj)
    .filter(([, value]) => typeof value === 'number')
    .map(([key, value]) => ({ value: value as number, label: key }));
}