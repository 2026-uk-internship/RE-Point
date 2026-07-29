package com.repoint.repoint.entity;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDateTime;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User {

    @Id
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Auth auth;

    @Column(nullable = false, unique = true, length = 20)
    private String name;

    @Column(length = 255)
    private String img;

    @Column(length = 255)
    private String comment;

    @Column(columnDefinition = "INT DEFAULT 100 CHECK (point >= 0)")
    private Integer point = 100;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "location_id")
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Location location;

    @Column(columnDefinition = "INT DEFAULT 0")
    private Integer temperature = 0;
}
