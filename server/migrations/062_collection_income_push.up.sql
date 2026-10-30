-- День, когда уже слали пуш «можно забрать доход коллекций».
ALTER TABLE web_push_preferences
    ADD COLUMN IF NOT EXISTS last_collection_income_push_date DATE;
