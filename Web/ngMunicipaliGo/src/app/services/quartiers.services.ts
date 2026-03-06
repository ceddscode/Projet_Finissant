export type BoundsLiteral = { north: number; south: number; east: number; west: number };
export type QuartierShape = { bounds: BoundsLiteral; polygon: google.maps.LatLngLiteral[] };

const toBounds = (pts: google.maps.LatLngLiteral[]): BoundsLiteral => {
  let north = pts[0].lat;
  let south = pts[0].lat;
  let east = pts[0].lng;
  let west = pts[0].lng;

  for (const p of pts) {
    if (p.lat > north) north = p.lat;
    if (p.lat < south) south = p.lat;
    if (p.lng > east) east = p.lng;
    if (p.lng < west) west = p.lng;
  }

  return { north, south, east, west };
};

export const QUARTIER_SHAPES: Record<string, QuartierShape> = {
  'Gentilly-du Tremblay': (() => {
    const polygon = [
      { lat: 45.57534, lng: -73.4722 },
      { lat: 45.56752, lng: -73.45283 },
      { lat: 45.55607, lng: -73.43032 },
      { lat: 45.5445, lng: -73.43969 },
      { lat: 45.53811, lng: -73.44163 },
      { lat: 45.53311, lng: -73.43213 },
      { lat: 45.52258, lng: -73.43396 },
      { lat: 45.52707, lng: -73.44807 },
      { lat: 45.53251, lng: -73.46132 },
      { lat: 45.53886, lng: -73.45587 },
      { lat: 45.54557, lng: -73.45487 },
      { lat: 45.55874, lng: -73.47068 },
      { lat: 45.56241, lng: -73.47547 },
      { lat: 45.56715, lng: -73.48186 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Fatima': (() => {
    const polygon = [
      { lat: 45.5754, lng: -73.47241 },
      { lat: 45.57814, lng: -73.47621 },
      { lat: 45.56801, lng: -73.48813 },
      { lat: 45.55162, lng: -73.50038 },
      { lat: 45.54599, lng: -73.49234 },
      { lat: 45.55106, lng: -73.48435 },
      { lat: 45.55265, lng: -73.48546 },
      { lat: 45.5557, lng: -73.48458 },
      { lat: 45.55844, lng: -73.48678 },
      { lat: 45.56056, lng: -73.48542 },
      { lat: 45.5655, lng: -73.48351 },
      { lat: 45.56912, lng: -73.47989 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Sacré-Cœur': (() => {
    const polygon = [
      { lat: 45.52484, lng: -73.44308 },
      { lat: 45.51982, lng: -73.44553 },
      { lat: 45.51716, lng: -73.45163 },
      { lat: 45.52928, lng: -73.48146 },
      { lat: 45.53718, lng: -73.47729 },
      { lat: 45.5369, lng: -73.46841 },
      { lat: 45.53285, lng: -73.46299 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Bellerive-Collectivité Nouvelle': (() => {
    const polygon = [
      { lat: 45.56695, lng: -73.48204 },
      { lat: 45.54557, lng: -73.45515 },
      { lat: 45.53915, lng: -73.456 },
      { lat: 45.53287, lng: -73.46167 },
      { lat: 45.53712, lng: -73.46813 },
      { lat: 45.53747, lng: -73.47678 },
      { lat: 45.54065, lng: -73.48689 },
      { lat: 45.54104, lng: -73.49016 },
      { lat: 45.54579, lng: -73.49175 },
      { lat: 45.55097, lng: -73.48415 },
      { lat: 45.55247, lng: -73.48488 },
      { lat: 45.55585, lng: -73.48426 },
      { lat: 45.55863, lng: -73.48604 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Carillon-Saint-Pie-X': (() => {
    const polygon = [
      { lat: 45.53734, lng: -73.47766 },
      { lat: 45.52965, lng: -73.48167 },
      { lat: 45.53579, lng: -73.49685 },
      { lat: 45.54128, lng: -73.49133 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Vieux-Longueuil': (() => {
    const polygon = [
      { lat: 45.55158, lng: -73.50066 },
      { lat: 45.54486, lng: -73.49193 },
      { lat: 45.54186, lng: -73.4915 },
      { lat: 45.53562, lng: -73.49748 },
      { lat: 45.53316, lng: -73.4911 },
      { lat: 45.5261, lng: -73.49634 },
      { lat: 45.52941, lng: -73.50579 },
      { lat: 45.53149, lng: -73.51148 },
      { lat: 45.52923, lng: -73.51309 },
      { lat: 45.53354, lng: -73.52329 },
      { lat: 45.5352, lng: -73.52225 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Notre-Dame-de-Grâces': (() => {
    const polygon = [
      { lat: 45.52927, lng: -73.48174 },
      { lat: 45.5331, lng: -73.49087 },
      { lat: 45.52582, lng: -73.49629 },
      { lat: 45.53122, lng: -73.51132 },
      { lat: 45.52904, lng: -73.51283 },
      { lat: 45.52002, lng: -73.48795 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Saint-Vincent-de-Paul': (() => {
    const polygon = [
      { lat: 45.52238, lng: -73.48595 },
      { lat: 45.52906, lng: -73.4816 },
      { lat: 45.52207, lng: -73.46455 },
      { lat: 45.51916, lng: -73.46403 },
      { lat: 45.51567, lng: -73.46654 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Roberval': (() => {
    const polygon = [
      { lat: 45.52235, lng: -73.434 },
      { lat: 45.51217, lng: -73.43994 },
      { lat: 45.51692, lng: -73.45138 },
      { lat: 45.51948, lng: -73.44521 },
      { lat: 45.52475, lng: -73.44265 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Saint-Jean-Vianney': (() => {
    const polygon = [
      { lat: 45.52211, lng: -73.48606 },
      { lat: 45.51552, lng: -73.46678 },
      { lat: 45.50638, lng: -73.47356 },
      { lat: 45.50555, lng: -73.48128 },
      { lat: 45.50484, lng: -73.48865 },
      { lat: 45.51082, lng: -73.4938 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Saint-Jude': (() => {
    const polygon = [
      { lat: 45.53338, lng: -73.52334 },
      { lat: 45.53412, lng: -73.52692 },
      { lat: 45.51856, lng: -73.52411 },
      { lat: 45.51179, lng: -73.5039 },
      { lat: 45.51444, lng: -73.50543 },
      { lat: 45.52899, lng: -73.51311 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Notre-Dame-de-la-Garde': (() => {
    const polygon = [
      { lat: 45.51436, lng: -73.50514 },
      { lat: 45.51089, lng: -73.4942 },
      { lat: 45.51991, lng: -73.48821 },
      { lat: 45.52881, lng: -73.51274 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Le Moyne': (() => {
    const polygon = [
      { lat: 45.51408, lng: -73.5049 },
      { lat: 45.51173, lng: -73.50351 },
      { lat: 45.50966, lng: -73.49811 },
      { lat: 45.50824, lng: -73.49691 },
      { lat: 45.50241, lng: -73.49231 },
      { lat: 45.4951, lng: -73.50002 },
      { lat: 45.49301, lng: -73.49708 },
      { lat: 45.50175, lng: -73.48797 },
      { lat: 45.50471, lng: -73.489 },
      { lat: 45.51064, lng: -73.49442 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),

  'Saint-Robert': (() => {
    const polygon = [
      { lat: 45.50634, lng: -73.47319 },
      { lat: 45.50779, lng: -73.44103 },
      { lat: 45.51174, lng: -73.44014 },
      { lat: 45.52091, lng: -73.46199 },
      { lat: 45.52187, lng: -73.46407 },
      { lat: 45.51931, lng: -73.46353 }
    ];
    return { polygon, bounds: toBounds(polygon) };
  })(),
};

export const QUARTIER_NAMES = Object.keys(QUARTIER_SHAPES).sort((a, b) => a.localeCompare(b));