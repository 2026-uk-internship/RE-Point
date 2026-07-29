package com.repoint.repoint.entity;

import jakarta.persistence.*;
import lombok.*;

// Table name is "search" (a reserved-ish word), class named SearchKeyword to avoid confusion
@Entity
@Table(name = "search")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SearchKeyword {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 255)
    private String title;

    @Column
    @Builder.Default
    private Integer count = 1;
}
