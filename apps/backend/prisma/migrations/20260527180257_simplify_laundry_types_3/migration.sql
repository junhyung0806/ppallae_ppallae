/*
  Warnings:

  - You are about to drop the column `absorption_level` on the `laundry_types` table. All the data in the column will be lost.
  - You are about to drop the column `airflow_level` on the `laundry_types` table. All the data in the column will be lost.
  - You are about to drop the column `surface_area_level` on the `laundry_types` table. All the data in the column will be lost.
  - You are about to drop the column `thickness_level` on the `laundry_types` table. All the data in the column will be lost.
  - Added the required column `description` to the `laundry_types` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "laundry_types" DROP COLUMN "absorption_level",
DROP COLUMN "airflow_level",
DROP COLUMN "surface_area_level",
DROP COLUMN "thickness_level",
ADD COLUMN     "description" TEXT NOT NULL,
ADD COLUMN     "examples" TEXT[];
