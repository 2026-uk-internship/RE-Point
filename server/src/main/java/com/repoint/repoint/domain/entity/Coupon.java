package com.repoint.domain.entity;

import com.repoint.domain.enums.CouponEffectType;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "coupons")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Coupon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String title;

    @Lob
    @Column(nullable = false)
    private String description;

    @Column(name = "valid_from")
    private LocalDateTime validFrom;

    @Column(name = "valid_until")
    private LocalDateTime validUntil;

    @Enumerated(EnumType.STRING)
    @Column(name = "effect_type", length = 30)
    private CouponEffectType effectType;

    @Column(name = "effect_value", nullable = false, precision = 10, scale = 2)
    private BigDecimal effectValue;

    @Column(name = "min_amount")
    @Builder.Default
    private Integer minAmount = 0;

    @Column(name = "max_discount")
    private Integer maxDiscount;
}
