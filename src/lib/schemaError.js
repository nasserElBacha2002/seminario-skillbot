const LEGACY_SCHEMA_CODES = new Set(['PGRST200', 'PGRST204', '42703', '42P01'])
const LEGACY_SCHEMA_TEXT = /output_template|use_case_fields|\burl\b/i

export function isLegacySchemaError(error) {
  if (!error || !LEGACY_SCHEMA_CODES.has(error.code)) return false
  const message = `${error.message ?? ''} ${error.details ?? ''} ${error.hint ?? ''}`
  return LEGACY_SCHEMA_TEXT.test(message)
}
