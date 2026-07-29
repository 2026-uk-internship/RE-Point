package com.repoint.domain.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "location")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Location {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String country;

    @Column(nullable = false, length = 255)
    private String region;

    @Column(nullable = false, length = 255)
    private String city;
}
