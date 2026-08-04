package com.repoint.domain.converter;

import com.repoint.domain.enums.TradeStatus;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class TradeStatusConverter implements AttributeConverter<TradeStatus, String> {
    @Override
    public String convertToDatabaseColumn(TradeStatus attribute) {
        return attribute == null ? null : attribute.getValue();
    }

    @Override
    public TradeStatus convertToEntityAttribute(String dbData) {
        return dbData == null ? null : TradeStatus.fromValue(dbData);
    }
}
