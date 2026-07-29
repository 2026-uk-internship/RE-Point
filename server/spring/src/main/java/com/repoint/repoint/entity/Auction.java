package com.repoint.repoint.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "auction")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Auction {

    // auction.product_id is both PK and FK referencing products.id (shared primary key)
    @Id
    @Column(name = "product_id")
    private Long productId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "product_id")
    private Product product;

    @Column(name = "start_point", nullable = false)
    private Integer startPoint;

    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "highest_user")
    private User highestUser;

    @Column(name = "highest_point", nullable = false)
    private Integer highestPoint;
}
