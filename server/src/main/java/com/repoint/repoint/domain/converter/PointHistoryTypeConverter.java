package com.repoint.domain.converter;

import com.repoint.domain.enums.PointHistoryType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class PointHistoryTypeConverter implements AttributeConverter<PointHistoryType, String> {
    @Override
    public String convertToDatabaseColumn(PointHistoryType attribute) {
        return attribute == null ? null : attribute.getValue();
    }

    @Override
    public PointHistoryType convertToEntityAttribute(String dbData) {
        return dbData == null ? null : PointHistoryType.fromValue(dbData);
    }
}
