package com.repoint.domain.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    // users.id is both PK and FK referencing auth.id (shared primary key)
    @Id
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "id")
    private Auth auth;

    @Column(nullable = false, unique = true, length = 20)
    private String name;

    @Column(length = 255)
    private String img;

    @Column(length = 255)
    private String comment;

    @Column
    @Builder.Default
    private Integer point = 100;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "location_id")
    private Location location;

    @Column
    @Builder.Default
    private Integer temperature = 0;
}
