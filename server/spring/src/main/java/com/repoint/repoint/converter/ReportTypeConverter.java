package com.repoint.domain.converter;

import com.repoint.domain.enums.ReportType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class ReportTypeConverter implements AttributeConverter<ReportType, String> {
    @Override
    public String convertToDatabaseColumn(ReportType attribute) {
        return attribute == null ? null : attribute.getValue();
    }

    @Override
    public ReportType convertToEntityAttribute(String dbData) {
        return dbData == null ? null : ReportType.fromValue(dbData);
    }
}
