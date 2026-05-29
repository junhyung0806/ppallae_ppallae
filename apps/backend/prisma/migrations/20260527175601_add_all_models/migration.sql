-- CreateTable
CREATE TABLE "regions" (
    "id" TEXT NOT NULL,
    "adm_code" TEXT NOT NULL,
    "sido" TEXT NOT NULL,
    "sigungu" TEXT NOT NULL,
    "eupmyeondong" TEXT NOT NULL,
    "nx" INTEGER NOT NULL,
    "ny" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "regions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "weather_snapshots" (
    "id" TEXT NOT NULL,
    "region_id" TEXT NOT NULL,
    "temperature_c" DOUBLE PRECISION NOT NULL,
    "humidity_percent" INTEGER NOT NULL,
    "wind_speed_mps" DOUBLE PRECISION NOT NULL,
    "precip_type" TEXT NOT NULL DEFAULT 'NONE',
    "sky_condition" TEXT NOT NULL DEFAULT 'CLEAR',
    "observed_at" TIMESTAMP(3) NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'KMA',
    "raw_payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "weather_snapshots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "weather_forecast_hourly" (
    "id" TEXT NOT NULL,
    "region_id" TEXT NOT NULL,
    "forecast_at" TIMESTAMP(3) NOT NULL,
    "temperature_c" DOUBLE PRECISION NOT NULL,
    "humidity_percent" INTEGER NOT NULL,
    "wind_speed_mps" DOUBLE PRECISION NOT NULL,
    "precip_type" TEXT NOT NULL DEFAULT 'NONE',
    "precipitation_probability" INTEGER NOT NULL DEFAULT 0,
    "sky_condition" TEXT NOT NULL DEFAULT 'CLEAR',
    "source" TEXT NOT NULL DEFAULT 'KMA',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "weather_forecast_hourly_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "air_quality_snapshots" (
    "id" TEXT NOT NULL,
    "region_id" TEXT NOT NULL,
    "pm10_value" DOUBLE PRECISION,
    "pm10_grade" INTEGER,
    "pm25_value" DOUBLE PRECISION,
    "pm25_grade" INTEGER,
    "station_name" TEXT,
    "observed_at" TIMESTAMP(3) NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'AIRKOREA',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "air_quality_snapshots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "laundry_types" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name_ko" TEXT NOT NULL,
    "thickness_level" INTEGER NOT NULL,
    "absorption_level" INTEGER NOT NULL,
    "surface_area_level" INTEGER NOT NULL,
    "airflow_level" INTEGER NOT NULL,
    "base_dry_hours_min" DOUBLE PRECISION NOT NULL,
    "base_dry_hours_max" DOUBLE PRECISION NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "caution_text" TEXT,
    "good_text" TEXT,
    "bad_text" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "laundry_types_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "laundry_score_results" (
    "id" TEXT NOT NULL,
    "region_id" TEXT NOT NULL,
    "laundry_type_id" TEXT NOT NULL,
    "drying_place" TEXT NOT NULL,
    "laundry_amount" TEXT NOT NULL DEFAULT 'MEDIUM',
    "overall_score" INTEGER NOT NULL,
    "outdoor_score" INTEGER,
    "indoor_score" INTEGER,
    "estimated_dry_hours_min" DOUBLE PRECISION NOT NULL,
    "estimated_dry_hours_max" DOUBLE PRECISION NOT NULL,
    "grade" TEXT NOT NULL,
    "recommendation_text" TEXT NOT NULL,
    "warning_texts" TEXT[],
    "best_start_time_range" TEXT,
    "generated_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "laundry_score_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "app_notices" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "priority" INTEGER NOT NULL DEFAULT 0,
    "start_at" TIMESTAMP(3),
    "end_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "app_notices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "app_configs" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "is_public" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "app_configs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "admin_users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'ADMIN',
    "last_login_at" TIMESTAMP(3),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "admin_users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "admin_user_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "target" TEXT,
    "detail" JSONB,
    "ip_address" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "regions_adm_code_key" ON "regions"("adm_code");

-- CreateIndex
CREATE INDEX "regions_nx_ny_idx" ON "regions"("nx", "ny");

-- CreateIndex
CREATE INDEX "regions_sido_sigungu_idx" ON "regions"("sido", "sigungu");

-- CreateIndex
CREATE INDEX "weather_snapshots_region_id_observed_at_idx" ON "weather_snapshots"("region_id", "observed_at");

-- CreateIndex
CREATE UNIQUE INDEX "weather_forecast_hourly_region_id_forecast_at_key" ON "weather_forecast_hourly"("region_id", "forecast_at");

-- CreateIndex
CREATE INDEX "air_quality_snapshots_region_id_observed_at_idx" ON "air_quality_snapshots"("region_id", "observed_at");

-- CreateIndex
CREATE UNIQUE INDEX "laundry_types_code_key" ON "laundry_types"("code");

-- CreateIndex
CREATE INDEX "laundry_score_results_region_id_generated_at_idx" ON "laundry_score_results"("region_id", "generated_at");

-- CreateIndex
CREATE INDEX "laundry_score_results_laundry_type_id_idx" ON "laundry_score_results"("laundry_type_id");

-- CreateIndex
CREATE UNIQUE INDEX "app_configs_key_key" ON "app_configs"("key");

-- CreateIndex
CREATE UNIQUE INDEX "admin_users_email_key" ON "admin_users"("email");

-- CreateIndex
CREATE INDEX "audit_logs_admin_user_id_idx" ON "audit_logs"("admin_user_id");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- AddForeignKey
ALTER TABLE "weather_snapshots" ADD CONSTRAINT "weather_snapshots_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "regions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "weather_forecast_hourly" ADD CONSTRAINT "weather_forecast_hourly_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "regions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "air_quality_snapshots" ADD CONSTRAINT "air_quality_snapshots_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "regions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "laundry_score_results" ADD CONSTRAINT "laundry_score_results_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "regions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "laundry_score_results" ADD CONSTRAINT "laundry_score_results_laundry_type_id_fkey" FOREIGN KEY ("laundry_type_id") REFERENCES "laundry_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_admin_user_id_fkey" FOREIGN KEY ("admin_user_id") REFERENCES "admin_users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
