package com.mamacare.caretaker;

import com.mamacare.common.BaseEntity;
import com.mamacare.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "caretaker_profiles")
@Getter
@Setter
@NoArgsConstructor
public class CaretakerProfile extends BaseEntity {
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    /** Free text, e.g. "Husband", "Mother". */
    @Column(length = 60)
    private String relationship;
}
