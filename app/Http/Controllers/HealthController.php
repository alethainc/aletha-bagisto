<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;
use Exception;

class HealthController extends Controller
{
    /**
     * Check the health status of critical services
     */
    public function check(): JsonResponse
    {
        $health = [
            'status' => 'healthy',
            'timestamp' => now()->toIso8601String(),
            'services' => [
                'database' => $this->checkDatabase(),
                'storage' => $this->checkStorage(),
                'cache' => $this->checkCache(),
            ],
            'version' => config('app.version', '2.2.3')
        ];

        $isHealthy = !in_array('unhealthy', array_column($health['services'], 'status'));
        $health['status'] = $isHealthy ? 'healthy' : 'unhealthy';

        return response()->json($health, $isHealthy ? 200 : 503);
    }

    /**
     * Check database connection
     */
    private function checkDatabase(): array
    {
        try {
            DB::connection()->getPdo();
            $result = [
                'status' => 'healthy',
                'message' => 'Database connection successful'
            ];
        } catch (Exception $e) {
            $result = [
                'status' => 'unhealthy',
                'message' => 'Database connection failed',
                'error' => $e->getMessage()
            ];
        }

        return $result;
    }

    /**
     * Check S3 storage access
     */
    private function checkStorage(): array
    {
        try {
            Storage::disk('s3')->exists('health-check.txt');
            $result = [
                'status' => 'healthy',
                'message' => 'S3 storage accessible',
                'disk' => config('filesystems.default')
            ];
        } catch (Exception $e) {
            $result = [
                'status' => 'unhealthy',
                'message' => 'S3 storage check failed',
                'error' => $e->getMessage()
            ];
        }

        return $result;
    }

    /**
     * Check cache system
     */
    private function checkCache(): array
    {
        try {
            $key = 'health-check-' . time();
            Cache::put($key, true, 30);
            $value = Cache::get($key);
            Cache::forget($key);

            $result = [
                'status' => 'healthy',
                'message' => 'Cache system operational',
                'driver' => config('cache.default')
            ];
        } catch (Exception $e) {
            $result = [
                'status' => 'unhealthy',
                'message' => 'Cache system check failed',
                'error' => $e->getMessage()
            ];
        }

        return $result;
    }
} 