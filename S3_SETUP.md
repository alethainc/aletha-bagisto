# Bagisto S3 Storage Configuration Guide

This guide explains how to configure Amazon S3 storage for Bagisto, particularly for handling product images and theme assets in production environments.

## Prerequisites

- An AWS account with access to S3
- AWS Access Key and Secret Key with S3 permissions
- An S3 bucket created for your application

## S3 Bucket Setup

1. Create a new S3 bucket or use an existing one
2. Configure bucket permissions:
   - Disable "Block all public access" if you want public access to images
   - Enable CORS if accessing from different domains

### Sample Bucket Policy
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
        }
    ]
}
```

### Sample CORS Configuration
```json
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET",
            "HEAD"
        ],
        "AllowedOrigins": [
            "*"
        ],
        "ExposeHeaders": [],
        "MaxAgeSeconds": 3000
    }
]
```

## Environment Configuration

Add the following variables to your `.env` file:

```bash
# S3 Configuration
FILESYSTEM_CLOUD=s3
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_DEFAULT_REGION=your_bucket_region
AWS_BUCKET=your_bucket_name
AWS_URL=https://your-bucket-name.s3.amazonaws.com
AWS_ENDPOINT=https://s3.your-region.amazonaws.com
AWS_USE_PATH_STYLE_ENDPOINT=true
AWS_FORCE_PATH_STYLE=true
```

Replace the placeholders with your actual AWS credentials and bucket information.

## Important Notes

1. **Existing Images**: When switching to S3:
   - New uploads will automatically use S3
   - Existing images need to be migrated to S3
   - Ensure proper ACL settings for existing objects

2. **Performance Optimization**:
   - Consider using CloudFront CDN for better performance
   - Set appropriate cache headers for your S3 objects

3. **Security Best Practices**:
   - Use IAM roles with minimal required permissions
   - Regularly rotate AWS access keys
   - Enable bucket logging for audit trails
   - Use bucket policies to restrict access as needed

4. **Troubleshooting**:
   - Check S3 bucket permissions if images return 403 errors
   - Verify CORS settings if accessing from different domains
   - Ensure proper URL configuration in `.env` file
   - Check file permissions when uploading new images

## Docker Environment

If running in Docker:

1. Ensure the AWS S3 SDK is installed:
   ```bash
   composer require league/flysystem-aws-s3-v3:"^3.0"
   ```

2. Environment variables should be passed to the container or set in the Docker environment file.

3. The container needs proper network access to communicate with AWS S3.

## ECS Health Check Configuration

When deploying to Amazon ECS, configure the following health check settings:

### Container Health Check
```json
{
    "healthCheck": {
        "command": [
            "CMD-SHELL",
            "curl -f http://localhost/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
    }
}
```

### Health Check Endpoint
Create a health check route in your Laravel application:

1. Add the following route to `routes/web.php`:
```php
Route::get('/health', function () {
    try {
        // Check database connection
        DB::connection()->getPdo();
        
        // Check storage access
        Storage::disk('s3')->exists('test.txt');
        
        // Check cache
        Cache::get('health-check-key');
        
        return response()->json([
            'status' => 'healthy',
            'services' => [
                'database' => 'connected',
                'storage' => 'accessible',
                'cache' => 'working'
            ]
        ], 200);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'unhealthy',
            'error' => $e->getMessage()
        ], 503);
    }
});
```

2. Configure your ECS service to use this endpoint for health checks:
   - Path: `/health`
   - Healthy threshold: 2
   - Unhealthy threshold: 3
   - Timeout: 5 seconds
   - Interval: 30 seconds
   - Success codes: 200
   - Initial health check grace period: 60 seconds

### Important Health Check Notes
- The health check endpoint verifies critical services:
  - Database connectivity
  - S3 storage accessibility
  - Cache system functionality
- Adjust timing parameters based on your application's startup time
- Consider adding additional checks specific to your setup
- Monitor health check logs for troubleshooting
- Set appropriate alerting based on health check status

## Testing Configuration

To verify your S3 setup:

1. Upload a test image through the admin panel
2. Verify the image URL points to your S3 bucket
3. Confirm the image is publicly accessible
4. Check browser console for any CORS-related errors

## Support

For additional support:
- Refer to [Laravel's Filesystem Documentation](https://laravel.com/docs/filesystem)
- Check [AWS S3 Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
- Visit [Bagisto's Documentation](https://docs.bagisto.com) 