"""Convert verified pipeline output to ECTMS-compatible GeoJSON FeatureCollection.

Every feature is WGS84, coordinates are 6-decimal, all SPROUT attributes are
properties. This is the payload a real batch would submit to ECTMS / EU TRACES.
"""
import json
from pathlib import Path


def round_coords(geom: dict) -> dict:
    """Round coordinates to 6 decimals, preserving GeoJSON structure."""
    def _walk(coord):
        if isinstance(coord, (int, float)):
            return round(float(coord), 6)
        return [_walk(c) for c in coord]
    return {'type': geom['type'], 'coordinates': _walk(geom['coordinates'])}


def to_ectms_feature(plot_record: dict) -> dict:
    props = {
        'batch_id': plot_record['batch_code'],
        'farm_id': plot_record['farm_id'],
        'plot_id': plot_record['plot_id'],
        'crop': plot_record.get('crop'),
        'area_ha': plot_record['declared_area_ha'],
        'verification_status': plot_record['status'],
        'model_version': plot_record.get('model_version'),
        'computed_at': plot_record.get('computed_at'),
    }
    for k, v in plot_record.get('attributes', {}).items():
        props[k] = v
    if plot_record.get('errors'):
        props['rejection_reasons'] = plot_record['errors']
    return {
        'type': 'Feature',
        'geometry': round_coords(plot_record['geometry']),
        'properties': props,
    }


def export(pipeline_result: dict, out_path: Path) -> dict:
    features = [to_ectms_feature(r) for r in pipeline_result['plots']]
    collection = {
        'type': 'FeatureCollection',
        'ectms_batch_id': pipeline_result['batch']['ectms_batch_id'],
        'batch_code': pipeline_result['batch']['batch_code'],
        'verification_status': pipeline_result['batch']['verification_status'],
        'generated_at': pipeline_result['batch']['computed_at'],
        'features': features,
    }
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(collection, f, indent=2)
    return collection