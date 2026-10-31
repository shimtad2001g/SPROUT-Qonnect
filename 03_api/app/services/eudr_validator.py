"""EUDR geolocation validator (rules R1-R8).

Shared by the API (boundary enforcement) and the audit script (report).
Input: GeoJSON geometry dict + optional declared area_ha.
Output: (shapely_geom or None, rules_passed:list[str], rules_failed:list[dict])

R1 CRS, R2 precision, R6 temporal, R7 response integrity, and R8 audit
trail are handled at higher layers (serialization, response envelope,
audit log). The validator enforces R3, R4, R5 here.
"""
from shapely.geometry import shape
from shapely.validation import explain_validity
from pyproj import Geod

GEOD = Geod(ellps='WGS84')
AREA_TOLERANCE = 0.05  # R5: 5% declared vs geodesic


def validate_geometry(geom_dict: dict, declared_area_ha: float | None = None):
    passed, failed = [], []
    gtype = geom_dict.get('type')

    # R3: area rule
    if gtype == 'Point':
        if declared_area_ha is not None and declared_area_ha > 4.0:
            failed.append({
                'rule_id': 'R3_area_rule',
                'message': f'Point cannot claim >4ha (declared {declared_area_ha}ha)',
            })
            return None, passed, failed
        passed.append('R3_area_rule')

    # R4: parse + validity
    try:
        geom = shape(geom_dict)
    except Exception as exc:
        failed.append({'rule_id': 'R4_parse', 'message': str(exc)})
        return None, passed, failed

    if not geom.is_valid:
        failed.append({
            'rule_id': 'R4_validity',
            'message': explain_validity(geom),
        })
        return geom, passed, failed
    passed.append('R4_validity')

    if gtype == 'Polygon':
        ring = geom_dict['coordinates'][0]
        if ring[0] != ring[-1]:
            failed.append({
                'rule_id': 'R4_ring_closed',
                'message': 'First vertex must equal last vertex',
            })
        else:
            passed.append('R4_ring_closed')

        if geom.exterior.is_ccw:
            passed.append('R4_ccw')
        else:
            failed.append({
                'rule_id': 'R4_ccw',
                'message': 'Exterior ring must be counter-clockwise',
            })

        # R5: declared vs geodesic area
        if declared_area_ha is not None and declared_area_ha > 0:
            try:
                geom_area_m2 = abs(GEOD.geometry_area_perimeter(geom)[0])
                geom_area_ha = geom_area_m2 / 10000.0
                delta = abs(geom_area_ha - declared_area_ha) / max(declared_area_ha, 1e-9)
                if delta <= AREA_TOLERANCE:
                    passed.append('R5_area_plausible')
                else:
                    failed.append({
                        'rule_id': 'R5_area_plausible',
                        'message': (
                            f'declared={declared_area_ha:.3f}ha '
                            f'geodesic={geom_area_ha:.3f}ha '
                            f'delta={delta*100:.1f}% (tolerance {AREA_TOLERANCE*100:.0f}%)'
                        ),
                        'geodesic_area_ha': round(geom_area_ha, 4),
                    })
            except Exception as exc:
                failed.append({'rule_id': 'R5_area_compute', 'message': str(exc)})

    return geom, passed, failed