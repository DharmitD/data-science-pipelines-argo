from typing import Optional, Callable

def set_k8s_pipeline_config(
    pipeline_func: Callable,
    pipeline_ttl: Optional[int] = None,
):
    """
    Sets pipeline-level configurations for Kubernetes platform.

    Args:
        pipeline_func: The pipeline function.
        pipeline_ttl: The pipeline TTL in seconds (optional).

    Returns:
        The modified pipeline function.
    """
    if not hasattr(pipeline_func, 'platforms'):
        pipeline_func.platforms = {}
    if 'kubernetes' not in pipeline_func.platforms:
        pipeline_func.platforms['kubernetes'] = {}
    if 'pipelineConfig' not in pipeline_func.platforms['kubernetes']:
        pipeline_func.platforms['kubernetes']['pipelineConfig'] = {}

    pipeline_config = pipeline_func.platforms['kubernetes']['pipelineConfig']

    if pipeline_ttl is not None:
        if pipeline_ttl <= 0:
            raise ValueError("pipeline_ttl must be a positive integer")
        pipeline_config['pipelineTtl'] = str(pipeline_ttl)

    return pipeline_func
